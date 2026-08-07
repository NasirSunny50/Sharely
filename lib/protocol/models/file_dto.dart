import 'package:meta/meta.dart';

/// Optional filesystem metadata for a file (§6.4.1). Both fields nullable.
@immutable
class FileMetadata {
  const FileMetadata({this.modified, this.accessed});

  factory FileMetadata.fromJson(Map<String, dynamic> json) => FileMetadata(
        modified: json['modified'] as String?,
        accessed: json['accessed'] as String?,
      );

  /// ISO-8601 last-modified timestamp (e.g. "2021-01-01T12:34:56Z").
  final String? modified;

  /// ISO-8601 last-accessed timestamp.
  final String? accessed;

  Map<String, dynamic> toJson() => {
        'modified': modified,
        'accessed': accessed,
      };

  bool get isEmpty => modified == null && accessed == null;

  @override
  bool operator ==(Object other) =>
      other is FileMetadata &&
      other.modified == modified &&
      other.accessed == accessed;

  @override
  int get hashCode => Object.hash(modified, accessed);

  @override
  String toString() => 'FileMetadata(modified: $modified, accessed: $accessed)';
}

/// A single file's metadata as sent in prepare-upload / prepare-download
/// (§6.4.1). The `files` map key must equal the inner [id].
///
/// Pure Dart — no Flutter imports.
@immutable
class FileDto {
  const FileDto({
    required this.id,
    required this.fileName,
    required this.size,
    required this.fileType,
    this.sha256,
    this.preview,
    this.metadata,
  });

  factory FileDto.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['metadata'];
    return FileDto(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      fileType: json['fileType'] as String? ?? 'application/octet-stream',
      sha256: json['sha256'] as String?,
      preview: json['preview'] as String?,
      metadata: rawMeta is Map<String, dynamic>
          ? FileMetadata.fromJson(rawMeta)
          : null,
    );
  }

  /// Opaque file identifier; equals the key under which this DTO appears.
  final String id;

  /// Display file name (e.g. "my image.png").
  final String fileName;

  /// Size in bytes.
  final int size;

  /// MIME type (e.g. "image/jpeg"). LocalSend always sends a string here.
  final String fileType;

  /// Optional SHA-256 of the file contents. Nullable (§6.4.1).
  final String? sha256;

  /// Optional preview data (e.g. a thumbnail). Nullable.
  final String? preview;

  /// Optional filesystem metadata. Nullable.
  final FileMetadata? metadata;

  /// Serializes to the wire shape. Nullable fields are only emitted when
  /// present, matching LocalSend's own encoder (it omits null metadata/preview
  /// rather than sending explicit nulls).
  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'size': size,
        'fileType': fileType,
        if (sha256 != null) 'sha256': sha256,
        if (preview != null) 'preview': preview,
        if (metadata != null && !metadata!.isEmpty)
          'metadata': metadata!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is FileDto &&
      other.id == id &&
      other.fileName == fileName &&
      other.size == size &&
      other.fileType == fileType &&
      other.sha256 == sha256 &&
      other.preview == preview &&
      other.metadata == metadata;

  @override
  int get hashCode =>
      Object.hash(id, fileName, size, fileType, sha256, preview, metadata);

  @override
  String toString() =>
      'FileDto(id: $id, fileName: $fileName, size: $size, type: $fileType)';
}
