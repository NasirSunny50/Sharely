import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/models/file_dto.dart';

void main() {
  group('FileDto', () {
    test('round-trips a full payload', () {
      const original = FileDto(
        id: 'some file id',
        fileName: 'my image.png',
        size: 324242,
        fileType: 'image/jpeg',
        sha256: 'deadbeef',
        preview: 'previewdata',
        metadata: FileMetadata(
          modified: '2021-01-01T12:34:56Z',
          accessed: '2021-01-01T12:34:56Z',
        ),
      );
      final decoded = FileDto.fromJson(original.toJson());
      expect(decoded, original);
    });

    test('parses the exact §6.4.1 example', () {
      final json = <String, dynamic>{
        'id': 'some file id',
        'fileName': 'my image.png',
        'size': 324242,
        'fileType': 'image/jpeg',
        'sha256': '*sha256 hash*',
        'preview': '*preview data*',
        'metadata': {
          'modified': '2021-01-01T12:34:56Z',
          'accessed': '2021-01-01T12:34:56Z',
        },
      };
      final file = FileDto.fromJson(json);
      expect(file.id, 'some file id');
      expect(file.size, 324242);
      expect(file.metadata?.modified, '2021-01-01T12:34:56Z');
    });

    test('handles missing nullable fields (sha256, preview, metadata)', () {
      final file = FileDto.fromJson(<String, dynamic>{
        'id': 'x',
        'fileName': 'notes.txt',
        'size': 10,
        'fileType': 'text/plain',
      });
      expect(file.sha256, isNull);
      expect(file.preview, isNull);
      expect(file.metadata, isNull);

      final json = file.toJson();
      // Null optionals are omitted, not emitted as null.
      expect(json.containsKey('sha256'), false);
      expect(json.containsKey('preview'), false);
      expect(json.containsKey('metadata'), false);
    });

    test('tolerates a 0-byte file and no extension', () {
      final file = FileDto.fromJson(<String, dynamic>{
        'id': 'z',
        'fileName': 'README',
        'size': 0,
        'fileType': 'application/octet-stream',
      });
      expect(file.size, 0);
      expect(file.fileName, 'README');
    });

    test('ignores unknown/extra fields', () {
      final file = FileDto.fromJson(<String, dynamic>{
        'id': 'z',
        'fileName': 'a.bin',
        'size': 5,
        'fileType': 'application/octet-stream',
        'legacyField': 42,
        'nested': {'a': 1},
      });
      expect(file.id, 'z');
      expect(file.size, 5);
    });

    test('metadata with only one field round-trips', () {
      const file = FileDto(
        id: 'm',
        fileName: 'x',
        size: 1,
        fileType: 'text/plain',
        metadata: FileMetadata(modified: '2020-01-01T00:00:00Z'),
      );
      final decoded = FileDto.fromJson(file.toJson());
      expect(decoded.metadata?.modified, '2020-01-01T00:00:00Z');
      expect(decoded.metadata?.accessed, isNull);
    });

    test('empty metadata is not emitted', () {
      const file = FileDto(
        id: 'm',
        fileName: 'x',
        size: 1,
        fileType: 'text/plain',
        metadata: FileMetadata(),
      );
      expect(file.toJson().containsKey('metadata'), false);
    });
  });
}
