import 'package:meta/meta.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/file_dto.dart';

/// Lifecycle state of a transfer session.
enum SessionState {
  /// Metadata exchanged, waiting to start (or awaiting accept on the receiver).
  pending,

  /// Files are actively transferring.
  active,

  /// All accepted files finished successfully.
  completed,

  /// Cancelled by either side (§6.4.3).
  cancelled,

  /// The receiver rejected the request (403).
  rejected,

  /// Failed due to an error (connection lost, disk full, etc.).
  failed,
}

/// Direction of a transfer relative to *this* device.
enum TransferDirection { sending, receiving }

/// Per-file transfer progress within a session.
@immutable
class FileProgress {
  const FileProgress({
    required this.file,
    this.token,
    this.bytesTransferred = 0,
    this.accepted = true,
    this.done = false,
    this.error,
  });

  final FileDto file;

  /// Upload token for this file, if the receiver accepted it. Null = not
  /// accepted (partial accept) or not yet prepared.
  final String? token;

  /// Bytes transferred so far. Streamed — never derived from a buffered whole.
  final int bytesTransferred;

  /// Whether the receiver accepted this file (false on partial-accept skip).
  final bool accepted;

  /// Whether this file has finished transferring.
  final bool done;

  /// Non-null if this file failed.
  final String? error;

  /// Fraction complete in [0, 1]. A 0-byte file is considered complete once
  /// [done] is set, avoiding a divide-by-zero.
  double get fraction {
    if (file.size <= 0) return done ? 1 : 0;
    final f = bytesTransferred / file.size;
    if (f < 0) return 0;
    if (f > 1) return 1;
    return f;
  }

  FileProgress copyWith({
    String? token,
    int? bytesTransferred,
    bool? accepted,
    bool? done,
    Object? error = _sentinel,
  }) {
    return FileProgress(
      file: file,
      token: token ?? this.token,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      accepted: accepted ?? this.accepted,
      done: done ?? this.done,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FileProgress &&
      other.file == file &&
      other.token == token &&
      other.bytesTransferred == bytesTransferred &&
      other.accepted == accepted &&
      other.done == done &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(file, token, bytesTransferred, accepted, done, error);
}

/// A transfer session: the runtime counterpart to the wire DTOs. Tracks the
/// remote peer, per-file progress, and overall state (§4 `session.dart`).
///
/// Pure Dart — no Flutter imports. Immutable; mutate via [copyWith].
@immutable
class Session {
  const Session({
    required this.sessionId,
    required this.remote,
    required this.direction,
    required this.files,
    this.state = SessionState.pending,
  });

  final String sessionId;

  /// The peer on the other end of this session.
  final DeviceInfo remote;

  final TransferDirection direction;

  /// Per-file progress, keyed by [FileDto.id].
  final Map<String, FileProgress> files;

  final SessionState state;

  /// Total bytes across all accepted files.
  int get totalBytes => files.values
      .where((p) => p.accepted)
      .fold(0, (sum, p) => sum + p.file.size);

  /// Total bytes transferred so far across all accepted files.
  int get transferredBytes => files.values
      .where((p) => p.accepted)
      .fold(0, (sum, p) => sum + p.bytesTransferred);

  /// Aggregate fraction complete in [0, 1].
  double get fraction {
    final total = totalBytes;
    if (total <= 0) {
      final accepted = files.values.where((p) => p.accepted).toList();
      if (accepted.isEmpty) return 0;
      return accepted.every((p) => p.done) ? 1 : 0;
    }
    return transferredBytes / total;
  }

  /// The tokens map (file id → token) for accepted files.
  Map<String, String> get tokens => {
        for (final entry in files.entries)
          if (entry.value.token != null) entry.key: entry.value.token!,
      };

  Session copyWith({
    String? sessionId,
    DeviceInfo? remote,
    TransferDirection? direction,
    Map<String, FileProgress>? files,
    SessionState? state,
  }) {
    return Session(
      sessionId: sessionId ?? this.sessionId,
      remote: remote ?? this.remote,
      direction: direction ?? this.direction,
      files: files ?? this.files,
      state: state ?? this.state,
    );
  }

  @override
  String toString() =>
      'Session($sessionId, $direction, ${state.name}, '
      'files: ${files.length}, ${(fraction * 100).toStringAsFixed(1)}%)';
}

const Object _sentinel = Object();
