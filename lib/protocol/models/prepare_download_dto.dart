import 'package:meta/meta.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/file_dto.dart';

/// Response to `POST /api/localsend/v2/prepare-download` (browser/reverse mode,
/// §6.5). Here the **sender** hosts and the receiver pulls: the response
/// carries the host's `info`, a `sessionId`, and the `files` available to
/// download (keyed by file id).
///
/// Pure Dart — no Flutter imports.
@immutable
class PrepareDownloadResponse {
  const PrepareDownloadResponse({
    required this.info,
    required this.sessionId,
    required this.files,
  });

  factory PrepareDownloadResponse.fromJson(Map<String, dynamic> json) {
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
    return PrepareDownloadResponse(
      info: info,
      sessionId: json['sessionId'] as String? ?? '',
      files: files,
    );
  }

  /// The hosting (sending) device's info block.
  final DeviceInfo info;

  /// Identifier for this download session (reused on browser refresh).
  final String sessionId;

  /// Files available to download, keyed by [FileDto.id].
  final Map<String, FileDto> files;

  Map<String, dynamic> toJson() => {
        'info': info.toJson(),
        'sessionId': sessionId,
        'files': {
          for (final entry in files.entries) entry.key: entry.value.toJson(),
        },
      };

  @override
  bool operator ==(Object other) =>
      other is PrepareDownloadResponse &&
      other.info == info &&
      other.sessionId == sessionId &&
      _mapEquals(other.files, files);

  @override
  int get hashCode =>
      Object.hash(info, sessionId, Object.hashAllUnordered(files.entries));

  @override
  String toString() =>
      'PrepareDownloadResponse(sessionId: $sessionId, files: ${files.length})';
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
