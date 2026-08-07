import 'package:meta/meta.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/file_dto.dart';

/// Body of `POST /api/localsend/v2/prepare-upload` (§6.4.1).
///
/// The sender describes itself (`info`) and the files it wants to send
/// (`files`, keyed by file id). Pure Dart — no Flutter imports.
@immutable
class PrepareUploadRequest {
  const PrepareUploadRequest({required this.info, required this.files});

  factory PrepareUploadRequest.fromJson(Map<String, dynamic> json) {
    final info = DeviceInfo.fromJson(
      (json['info'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final rawFiles =
        (json['files'] as Map?)?.cast<String, dynamic>() ?? const {};
    final files = <String, FileDto>{};
    rawFiles.forEach((key, value) {
      if (value is Map) {
        files[key] = FileDto.fromJson(value.cast<String, dynamic>());
      }
    });
    return PrepareUploadRequest(info: info, files: files);
  }

  /// The sending device's info block.
  final DeviceInfo info;

  /// Files to be sent, keyed by [FileDto.id]. The map key must equal the
  /// inner file id.
  final Map<String, FileDto> files;

  Map<String, dynamic> toJson() => {
        'info': info.toJson(),
        'files': {
          for (final entry in files.entries) entry.key: entry.value.toJson(),
        },
      };

  @override
  bool operator ==(Object other) =>
      other is PrepareUploadRequest &&
      other.info == info &&
      _mapEquals(other.files, files);

  @override
  int get hashCode => Object.hash(info, Object.hashAllUnordered(files.entries));

  @override
  String toString() =>
      'PrepareUploadRequest(info: $info, files: ${files.length})';
}

/// Response to a successful `prepare-upload` (§6.4.1).
///
/// The receiver returns a [sessionId] and a token per **accepted** file. On a
/// partial accept, only the accepted subset appears in [files].
@immutable
class PrepareUploadResponse {
  const PrepareUploadResponse({required this.sessionId, required this.files});

  factory PrepareUploadResponse.fromJson(Map<String, dynamic> json) {
    final rawFiles =
        (json['files'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PrepareUploadResponse(
      sessionId: json['sessionId'] as String? ?? '',
      files: {
        for (final entry in rawFiles.entries)
          entry.key: entry.value as String,
      },
    );
  }

  /// Identifier for this transfer session.
  final String sessionId;

  /// Map of file id → upload token, for the accepted files only.
  final Map<String, String> files;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'files': files,
      };

  @override
  bool operator ==(Object other) =>
      other is PrepareUploadResponse &&
      other.sessionId == sessionId &&
      _mapEquals(other.files, files);

  @override
  int get hashCode =>
      Object.hash(sessionId, Object.hashAllUnordered(files.entries));

  @override
  String toString() =>
      'PrepareUploadResponse(sessionId: $sessionId, files: ${files.length})';
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
