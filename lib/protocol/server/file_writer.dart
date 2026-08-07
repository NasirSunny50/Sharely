import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Streams an incoming file to disk without ever holding it fully in memory
/// (see the streaming constraint, §2.6). Resolves filename collisions and
/// cleans up the partial file on cancel/failure (§6.4.3).
///
/// Pure Dart (`dart:io`). One [ReceivingFile] per file in a session.
class ReceivingFile {
  ReceivingFile({
    required this.saveDir,
    required this.fileName,
    required this.expectedSize,
  });

  final Directory saveDir;

  /// The requested file name (sanitized before use).
  final String fileName;

  /// Expected total size in bytes (for progress); 0 is allowed.
  final int expectedSize;

  File? _target;
  IOSink? _sink;
  int _bytesWritten = 0;
  bool _closed = false;

  int get bytesWritten => _bytesWritten;

  /// The final path once opened, or null before [open].
  String? get path => _target?.path;

  bool get isComplete => _closed && _bytesWritten >= expectedSize;

  /// Opens a collision-safe target file for writing. Must be called once
  /// before [writeChunk].
  Future<void> open() async {
    if (_target != null) return;
    if (!saveDir.existsSync()) {
      saveDir.createSync(recursive: true);
    }
    final resolved = _resolveCollision(saveDir, _sanitize(fileName));
    _target = File(resolved);
    _sink = _target!.openWrite();
  }

  /// Appends a chunk. Streamed straight to the sink — no accumulation.
  Future<void> writeChunk(List<int> chunk) async {
    final sink = _sink;
    if (sink == null || _closed) {
      throw StateError('writeChunk before open() or after close');
    }
    sink.add(chunk);
    _bytesWritten += chunk.length;
  }

  /// Flushes and closes the file. Call on successful completion.
  Future<void> finish() async {
    if (_closed) return;
    _closed = true;
    await _sink?.flush();
    await _sink?.close();
  }

  /// Aborts: closes the sink and deletes the partial file (§6.4.3 — the
  /// receiver must delete partial files on cancel).
  Future<void> abort() async {
    if (_closed) {
      // Already finished; still remove if the caller aborts a completed file
      // (e.g. whole-session cancel).
    }
    _closed = true;
    try {
      await _sink?.close();
    } on Object {
      // ignore close errors during abort
    }
    final target = _target;
    if (target != null && target.existsSync()) {
      try {
        await target.delete();
      } on Object {
        // best-effort cleanup
      }
    }
  }

  /// Removes characters that are unsafe in a filename across platforms, and
  /// strips any path separators so a malicious name can't escape [saveDir].
  static String _sanitize(String name) {
    // Take only the final path component, then replace reserved chars.
    final base = p.basename(name).trim();
    var cleaned = base.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_');
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      return 'received_file';
    }
    // Cap length to stay well under filesystem limits (e.g. Windows MAX_PATH),
    // preserving the extension. A 300-char name shouldn't fail the transfer.
    const maxLen = 150;
    if (cleaned.length > maxLen) {
      final ext = p.extension(cleaned);
      final stem = p.basenameWithoutExtension(cleaned);
      final keep = (maxLen - ext.length).clamp(1, maxLen);
      cleaned = stem.substring(0, keep.clamp(0, stem.length)) + ext;
    }
    return cleaned;
  }

  /// If `dir/name` exists, appends " (1)", " (2)", … before the extension.
  static String _resolveCollision(Directory dir, String name) {
    var candidate = p.join(dir.path, name);
    if (!File(candidate).existsSync()) return candidate;

    final ext = p.extension(name); // includes the dot, or '' if none
    final stem = p.basenameWithoutExtension(name);
    var i = 1;
    do {
      candidate = p.join(dir.path, '$stem ($i)$ext');
      i++;
    } while (File(candidate).existsSync());
    return candidate;
  }
}
