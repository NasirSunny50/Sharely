import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:sharely/core/logger.dart';
import 'package:sharely/protocol/models/prepare_upload_dto.dart';
import 'package:sharely/protocol/models/session.dart';
import 'package:sharely/protocol/security/pin_guard.dart';
import 'package:sharely/protocol/server/file_writer.dart';

/// Decides which files of an incoming request to accept. Returns the set of
/// accepted file ids — all of them (accept), a subset (partial accept), or
/// empty (reject). May await user interaction (the incoming-request sheet) or
/// resolve immediately (favorites / Quick Save).
typedef AcceptResolver = Future<Set<String>> Function(
  PrepareUploadRequest request,
  String remoteIp,
);

/// Result of a prepare-upload, mapped to HTTP by the route.
@immutable
sealed class PrepareOutcome {
  const PrepareOutcome();
}

/// 200 — accepted (fully or partially); carries the session id + tokens.
class PrepareAccepted extends PrepareOutcome {
  const PrepareAccepted(this.response);
  final PrepareUploadResponse response;
}

/// 204 — nothing to transfer (empty file set).
class PrepareFinished extends PrepareOutcome {
  const PrepareFinished();
}

/// A non-2xx outcome with the HTTP status to emit (§6.4.1 error table).
class PrepareFailed extends PrepareOutcome {
  const PrepareFailed(this.statusCode, this.message);
  final int statusCode;
  final String message;
}

/// Result of validating/handling an upload call, mapped to HTTP by the route.
@immutable
class UploadError implements Exception {
  const UploadError(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'UploadError($statusCode, $message)';
}

/// Owns the single active **receive** session (§6.4). Enforces one session at a
/// time (409 for others), validates upload tokens and the uploader's IP, writes
/// streamed bytes to disk, and cleans up partial files on cancel.
///
/// Pure Dart. The save directory and accept policy are injected.
class ReceiveSessionManager {
  ReceiveSessionManager({
    required this.saveDir,
    required this.acceptResolver,
    PinGuard? pinGuard,
    Random? random,
  })  : pinGuard = pinGuard ?? PinGuard(),
        _random = random ?? Random.secure();

  static const _tag = 'Receive';

  /// Where received files are written. May be swapped from settings.
  Directory saveDir;

  final AcceptResolver acceptResolver;
  final PinGuard pinGuard;
  final Random _random;

  // Active session state.
  Session? _session;
  String? _sessionId;
  String? _remoteIp;
  bool _preparing = false;
  final Map<String, String> _tokenToFileId = {}; // token -> fileId
  final Map<String, String> _fileIdToToken = {}; // fileId -> token
  final Map<String, ReceivingFile> _writers = {}; // fileId -> writer

  final StreamController<Session> _sessionController =
      StreamController<Session>.broadcast();

  /// Emits the session on every progress/state change (for the receiving UI).
  Stream<Session> get sessionUpdates => _sessionController.stream;

  Session? get activeSession => _session;

  bool get hasActiveSession =>
      _session != null &&
      (_session!.state == SessionState.pending ||
          _session!.state == SessionState.active);

  /// Handles `prepare-upload` (§6.4.1). [pin] is the `?pin=` query value.
  Future<PrepareOutcome> prepareUpload(
    PrepareUploadRequest request,
    String remoteIp, {
    String? pin,
  }) async {
    // PIN gate first (§6.4.1: 401 required/invalid, 429 too many).
    switch (pinGuard.check(pin)) {
      case PinCheckResult.notRequired:
      case PinCheckResult.ok:
        break;
      case PinCheckResult.invalid:
        return const PrepareFailed(401, 'PIN required or invalid');
      case PinCheckResult.tooManyAttempts:
        return const PrepareFailed(429, 'Too many attempts');
    }

    // One active session at a time (§6.4.1: 409 blocked by another session).
    if (hasActiveSession || _preparing) {
      return const PrepareFailed(409, 'Blocked by another session');
    }

    if (request.files.isEmpty) {
      return const PrepareFinished(); // 204
    }

    _preparing = true;
    Set<String> accepted;
    try {
      accepted = await acceptResolver(request, remoteIp);
    } on Object catch (e) {
      _preparing = false;
      SharelyLogger.instance.e(_tag, 'accept resolver failed: $e');
      return const PrepareFailed(500, 'Unknown error');
    }

    // Keep only ids that were actually offered.
    accepted = accepted.where(request.files.containsKey).toSet();

    if (accepted.isEmpty) {
      _preparing = false;
      return const PrepareFailed(403, 'Rejected'); // 403
    }

    final sessionId = _randomId(16);
    final tokens = <String, String>{};
    final progress = <String, FileProgress>{};
    for (final entry in request.files.entries) {
      final id = entry.key;
      final isAccepted = accepted.contains(id);
      final token = isAccepted ? _randomId(20) : null;
      if (token != null) {
        tokens[id] = token;
        _tokenToFileId[token] = id;
        _fileIdToToken[id] = token;
      }
      progress[id] = FileProgress(
        file: entry.value,
        token: token,
        accepted: isAccepted,
      );
    }

    _sessionId = sessionId;
    _remoteIp = remoteIp;
    _session = Session(
      sessionId: sessionId,
      remote: request.info,
      direction: TransferDirection.receiving,
      files: progress,
    );
    _preparing = false;
    _emit();
    SharelyLogger.instance.i(
      _tag,
      'Session $sessionId accepted ${accepted.length}/${request.files.length} '
      'files from $remoteIp',
    );
    return PrepareAccepted(
      PrepareUploadResponse(sessionId: sessionId, files: tokens),
    );
  }

  /// Streams an `upload` body to disk (§6.4.2). Validates session/token/IP,
  /// then writes [body] chunk-by-chunk. Throws [UploadError] on any protocol
  /// violation so the route can map it to a status code.
  Future<void> handleUpload({
    required String? sessionId,
    required String? fileId,
    required String? token,
    required String remoteIp,
    required Stream<List<int>> body,
  }) async {
    if (sessionId == null || fileId == null || token == null) {
      throw const UploadError(400, 'Missing parameters');
    }
    if (sessionId != _sessionId || _session == null) {
      throw const UploadError(409, 'Blocked by another session');
    }
    // Validate the uploading IP matches the session creator (§6.4.2).
    if (remoteIp != _remoteIp) {
      throw const UploadError(403, 'Invalid IP address');
    }
    if (_tokenToFileId[token] != fileId || _fileIdToToken[fileId] != token) {
      throw const UploadError(403, 'Invalid token');
    }

    final fileProgress = _session!.files[fileId];
    if (fileProgress == null || !fileProgress.accepted) {
      throw const UploadError(403, 'File not accepted');
    }

    _setState(SessionState.active);

    final writer = _writers.putIfAbsent(
      fileId,
      () => ReceivingFile(
        saveDir: saveDir,
        fileName: fileProgress.file.fileName,
        expectedSize: fileProgress.file.size,
      ),
    );
    await writer.open();

    try {
      await for (final chunk in body) {
        await writer.writeChunk(chunk);
        _updateFileBytes(fileId, writer.bytesWritten);
      }
      // A stream that ends short of the declared size is a truncated/aborted
      // upload (e.g. sender died) — do not keep the partial file.
      if (writer.bytesWritten < fileProgress.file.size) {
        await writer.abort();
        throw const UploadError(500, 'Truncated upload');
      }
      await writer.finish();
      _markFileDone(fileId);
    } on UploadError {
      rethrow;
    } on Object catch (e) {
      SharelyLogger.instance.w(_tag, 'upload $fileId failed: $e');
      await writer.abort();
      throw const UploadError(500, 'Upload failed');
    }
  }

  /// Handles `cancel` (§6.4.3): aborts all writers (deleting partial files) and
  /// clears the session. Ignores a mismatched/absent session id.
  Future<void> cancel(String? sessionId) async {
    if (sessionId == null || sessionId != _sessionId) return;
    SharelyLogger.instance.i(_tag, 'Session $sessionId cancelled');
    await _abortAllWriters();
    _setState(SessionState.cancelled);
    _clear();
  }

  Future<void> _abortAllWriters() async {
    for (final writer in _writers.values) {
      await writer.abort();
    }
  }

  void _updateFileBytes(String fileId, int bytes) {
    final session = _session;
    if (session == null) return;
    final fp = session.files[fileId];
    if (fp == null) return;
    final updated = Map<String, FileProgress>.from(session.files)
      ..[fileId] = fp.copyWith(bytesTransferred: bytes);
    _session = session.copyWith(files: updated);
    _emit();
  }

  void _markFileDone(String fileId) {
    final session = _session;
    if (session == null) return;
    final fp = session.files[fileId];
    if (fp == null) return;
    final updated = Map<String, FileProgress>.from(session.files)
      ..[fileId] = fp.copyWith(
        done: true,
        bytesTransferred: fp.file.size,
      );
    var next = session.copyWith(files: updated);

    final allDone = next.files.values
        .where((p) => p.accepted)
        .every((p) => p.done);
    if (allDone) {
      next = next.copyWith(state: SessionState.completed);
    }
    _session = next;
    _emit();

    if (allDone) {
      SharelyLogger.instance.i(_tag, 'Session ${session.sessionId} complete');
      _clear();
    }
  }

  void _setState(SessionState state) {
    final session = _session;
    if (session == null || session.state == state) return;
    _session = session.copyWith(state: state);
    _emit();
  }

  void _clear() {
    _sessionId = null;
    _remoteIp = null;
    _tokenToFileId.clear();
    _fileIdToToken.clear();
    _writers.clear();
    // Keep _session as the terminal snapshot for the UI; hasActiveSession is
    // false once state is terminal.
  }

  void _emit() {
    final session = _session;
    if (session != null && !_sessionController.isClosed) {
      _sessionController.add(session);
    }
  }

  String _randomId(int bytes) {
    const chars = '0123456789abcdef';
    final sb = StringBuffer();
    for (var i = 0; i < bytes * 2; i++) {
      sb.write(chars[_random.nextInt(16)]);
    }
    return sb.toString();
  }

  Future<void> dispose() async {
    await _abortAllWriters();
    await _sessionController.close();
  }
}
