import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/models/device_type.dart';
import 'package:sharely/protocol/models/prepare_download_dto.dart';
import 'package:sharely/protocol/models/prepare_upload_dto.dart';

void main() {
  group('PrepareUploadRequest', () {
    test('parses the exact §6.4.1 example and round-trips', () {
      final json = <String, dynamic>{
        'info': {
          'alias': 'Nice Orange',
          'version': '2.0',
          'deviceModel': 'Samsung',
          'deviceType': 'mobile',
          'fingerprint': 'random string',
          'port': 53317,
          'protocol': 'https',
          'download': true,
        },
        'files': {
          'some file id': {
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
          },
        },
      };

      final req = PrepareUploadRequest.fromJson(json);
      expect(req.info.alias, 'Nice Orange');
      expect(req.info.deviceType, DeviceType.mobile);
      expect(req.files.length, 1);
      expect(req.files['some file id']!.size, 324242);

      // The map key must equal the inner id.
      expect(req.files.keys.single, req.files.values.single.id);

      // Round-trip.
      final decoded = PrepareUploadRequest.fromJson(req.toJson());
      expect(decoded, req);
    });

    test('handles a multi-file batch', () {
      final json = <String, dynamic>{
        'info': {
          'alias': 'A',
          'version': '2.0',
          'fingerprint': 'f',
          'port': 53317,
          'protocol': 'http',
        },
        'files': {
          for (var i = 0; i < 20; i++)
            'id$i': {
              'id': 'id$i',
              'fileName': 'f$i.bin',
              'size': i,
              'fileType': 'application/octet-stream',
            },
        },
      };
      final req = PrepareUploadRequest.fromJson(json);
      expect(req.files.length, 20);
      expect(PrepareUploadRequest.fromJson(req.toJson()), req);
    });
  });

  group('PrepareUploadResponse', () {
    test('round-trips and models a partial accept', () {
      final json = <String, dynamic>{
        'sessionId': 'mySessionId',
        'files': {'someFileId': 'someFileToken'},
      };
      final res = PrepareUploadResponse.fromJson(json);
      expect(res.sessionId, 'mySessionId');
      expect(res.files, {'someFileId': 'someFileToken'});
      expect(PrepareUploadResponse.fromJson(res.toJson()), res);
    });

    test('an empty files map (full reject-to-none) is valid', () {
      final res = PrepareUploadResponse.fromJson(<String, dynamic>{
        'sessionId': 's',
        'files': <String, dynamic>{},
      });
      expect(res.files, isEmpty);
    });
  });

  group('PrepareDownloadResponse', () {
    test('round-trips info + sessionId + files', () {
      final json = <String, dynamic>{
        'info': {
          'alias': 'Host',
          'version': '2.0',
          'fingerprint': 'f',
          'port': 53317,
          'protocol': 'http',
          'download': true,
        },
        'sessionId': 'dl-1',
        'files': {
          'a': {
            'id': 'a',
            'fileName': 'a.txt',
            'size': 3,
            'fileType': 'text/plain',
          },
        },
      };
      final res = PrepareDownloadResponse.fromJson(json);
      expect(res.info.alias, 'Host');
      expect(res.sessionId, 'dl-1');
      expect(res.files['a']!.fileName, 'a.txt');
      expect(PrepareDownloadResponse.fromJson(res.toJson()), res);
    });
  });
}
