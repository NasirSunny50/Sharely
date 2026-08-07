@Tags(['slow'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';
import 'package:sharely/protocol/models/file_dto.dart';
import 'package:sharely/protocol/models/prepare_upload_dto.dart';
import 'package:sharely/protocol/security/pin_guard.dart';
import 'package:sharely/protocol/server/http_server.dart';
import 'package:sharely/protocol/server/session_manager.dart';

const _self = DeviceInfo(
  alias: 'Sharely Receiver',
  version: '2.0',
  deviceType: DeviceType.desktop,
  fingerprint: 'receiver-fp',
  port: 53317,
  protocol: Protocol.http,
);

const _sender = DeviceInfo(
  alias: 'LocalSend Sender',
  version: '2.0',
  deviceType: DeviceType.mobile,
  fingerprint: 'sender-fp',
  port: 53317,
  protocol: Protocol.http,
);

/// Minimal LocalSend-compatible sending client used to drive the receiver.
class _FakeSender {
  _FakeSender(this.baseUrl);
  final String baseUrl;
  final _client = HttpClient();

  Future<HttpClientResponse> prepareUpload(
    Map<String, FileDto> files, {
    String? pin,
  }) async {
    final req = PrepareUploadRequest(info: _sender, files: files);
    var url = '$baseUrl/api/localsend/v2/prepare-upload';
    if (pin != null) url += '?pin=$pin';
    final r = await _client.postUrl(Uri.parse(url));
    r.headers.contentType = ContentType.json;
    r.write(jsonEncode(req.toJson()));
    return r.close();
  }

  Future<int> upload(
    String sessionId,
    String fileId,
    String token,
    List<int> bytes,
  ) async {
    final url =
        '$baseUrl/api/localsend/v2/upload?sessionId=$sessionId&fileId=$fileId&token=$token';
    final r = await _client.postUrl(Uri.parse(url));
    r.add(bytes);
    final resp = await r.close();
    await resp.drain<void>();
    return resp.statusCode;
  }

  Future<int> cancel(String sessionId) async {
    final r = await _client.postUrl(
      Uri.parse('$baseUrl/api/localsend/v2/cancel?sessionId=$sessionId'),
    );
    final resp = await r.close();
    await resp.drain<void>();
    return resp.statusCode;
  }

  void close() => _client.close(force: true);
}

FileDto _fileDto(String id, String name, int size) =>
    FileDto(id: id, fileName: name, size: size, fileType: 'application/octet-stream');

Uint8List _randomBytes(int n, {int seed = 7}) {
  final rnd = Random(seed);
  final b = Uint8List(n);
  for (var i = 0; i < n; i++) {
    b[i] = rnd.nextInt(256);
  }
  return b;
}

void main() {
  late Directory saveDir;
  late ReceiveSessionManager manager;
  late SharelyHttpServer server;
  late _FakeSender sender;
  // Default accept policy; individual tests can swap the resolver.
  late Set<String> Function(PrepareUploadRequest) policy;

  Future<void> boot() async {
    manager = ReceiveSessionManager(
      saveDir: saveDir,
      acceptResolver: (req, ip) async => policy(req),
      pinGuard: PinGuard(),
    );
    server = SharelyHttpServer(
      deviceInfo: _self,
      port: 0,
      receiveManager: manager,
    );
    await server.start();
    sender = _FakeSender('http://127.0.0.1:${server.boundPort}');
  }

  setUp(() async {
    saveDir = Directory.systemTemp.createTempSync('sharely_recv');
    policy = (req) => req.files.keys.toSet(); // accept all by default
    await boot();
  });

  tearDown(() async {
    sender.close();
    await server.stop();
    await manager.dispose();
    if (saveDir.existsSync()) saveDir.deleteSync(recursive: true);
  });

  Future<void> expectFileOnDisk(String name, List<int> expected) async {
    final f = File(p.join(saveDir.path, name));
    expect(f.existsSync(), isTrue, reason: '$name should exist');
    final actual = await f.readAsBytes();
    expect(
      sha256.convert(actual),
      sha256.convert(expected),
      reason: '$name must be byte-identical',
    );
  }

  test('single file arrives byte-identical (SHA-256)', () async {
    final bytes = _randomBytes(64 * 1024);
    final files = {'f1': _fileDto('f1', 'photo.bin', bytes.length)};

    final prep = await sender.prepareUpload(files);
    expect(prep.statusCode, 200);
    final body =
        jsonDecode(await prep.transform(utf8.decoder).join()) as Map<String, dynamic>;
    final res = PrepareUploadResponse.fromJson(body);
    expect(res.files.keys, ['f1']);

    final status = await sender.upload(res.sessionId, 'f1', res.files['f1']!, bytes);
    expect(status, 200);
    await expectFileOnDisk('photo.bin', bytes);
  });

  test('20 files all arrive byte-identical', () async {
    final data = <String, Uint8List>{};
    final files = <String, FileDto>{};
    for (var i = 0; i < 20; i++) {
      final b = _randomBytes(1024 + i, seed: i);
      data['f$i'] = b;
      files['f$i'] = _fileDto('f$i', 'file$i.bin', b.length);
    }
    final prep = await sender.prepareUpload(files);
    final res = PrepareUploadResponse.fromJson(
      jsonDecode(await prep.transform(utf8.decoder).join()) as Map<String, dynamic>,
    );
    for (var i = 0; i < 20; i++) {
      final s = await sender.upload(res.sessionId, 'f$i', res.files['f$i']!, data['f$i']!);
      expect(s, 200);
    }
    for (var i = 0; i < 20; i++) {
      await expectFileOnDisk('file$i.bin', data['f$i']!);
    }
  });

  test('a large (16 MB) file streams to disk byte-identical', () async {
    final bytes = _randomBytes(16 * 1024 * 1024, seed: 99);
    final files = {'big': _fileDto('big', 'big.bin', bytes.length)};
    final prep = await sender.prepareUpload(files);
    final res = PrepareUploadResponse.fromJson(
      jsonDecode(await prep.transform(utf8.decoder).join()) as Map<String, dynamic>,
    );
    final s = await sender.upload(res.sessionId, 'big', res.files['big']!, bytes);
    expect(s, 200);
    await expectFileOnDisk('big.bin', bytes);
  });

  test('reject: resolver returns empty -> 403, nothing written', () async {
    policy = (_) => <String>{};
    final files = {'f1': _fileDto('f1', 'x.bin', 10)};
    final prep = await sender.prepareUpload(files);
    expect(prep.statusCode, 403);
    await prep.drain<void>();
    expect(saveDir.listSync(), isEmpty);
  });

  test('partial accept: only accepted files get tokens', () async {
    policy = (req) => {'a'}; // accept only 'a'
    final files = {
      'a': _fileDto('a', 'a.bin', 4),
      'b': _fileDto('b', 'b.bin', 4),
    };
    final prep = await sender.prepareUpload(files);
    final res = PrepareUploadResponse.fromJson(
      jsonDecode(await prep.transform(utf8.decoder).join()) as Map<String, dynamic>,
    );
    expect(res.files.keys, ['a']); // only accepted file has a token
    final ok = await sender.upload(res.sessionId, 'a', res.files['a']!, [1, 2, 3, 4]);
    expect(ok, 200);
  });

  test('empty file set -> 204', () async {
    final prep = await sender.prepareUpload(const {});
    expect(prep.statusCode, 204);
    await prep.drain<void>();
  });

  test('a second concurrent session is blocked with 409', () async {
    // First session prepared and left active (not uploaded).
    final files1 = {'f1': _fileDto('f1', 'a.bin', 8)};
    final prep1 = await sender.prepareUpload(files1);
    expect(prep1.statusCode, 200);
    await prep1.drain<void>();

    final other = _FakeSender('http://127.0.0.1:${server.boundPort}');
    addTearDown(other.close);
    final prep2 = await other.prepareUpload({'g': _fileDto('g', 'b.bin', 8)});
    expect(prep2.statusCode, 409);
    await prep2.drain<void>();
  });

  test('invalid token -> 403', () async {
    final files = {'f1': _fileDto('f1', 'a.bin', 4)};
    final prep = await sender.prepareUpload(files);
    final res = PrepareUploadResponse.fromJson(
      jsonDecode(await prep.transform(utf8.decoder).join()) as Map<String, dynamic>,
    );
    final s = await sender.upload(res.sessionId, 'f1', 'wrong-token', [1, 2, 3, 4]);
    expect(s, 403);
  });

  test('upload to an unknown session -> 409', () async {
    final s = await sender.upload('no-such-session', 'f1', 'tok', [1]);
    expect(s, 409);
  });

  test('cancel mid-upload deletes the partial file and frees the session',
      () async {
    // Prepare a large file, then feed a body stream we control so the upload is
    // genuinely in flight when cancel arrives (§6.4.3).
    final req = PrepareUploadRequest(
      info: _sender,
      files: {'f1': _fileDto('f1', 'partial.bin', 10 * 1024 * 1024)},
    );
    final outcome = await manager.prepareUpload(req, '127.0.0.1');
    final res = (outcome as PrepareAccepted).response;

    final body = StreamController<List<int>>();
    final uploadFuture = manager.handleUpload(
      sessionId: res.sessionId,
      fileId: 'f1',
      token: res.files['f1'],
      remoteIp: '127.0.0.1',
      body: body.stream,
    );

    body.add(_randomBytes(1024)); // some bytes land on disk
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await manager.cancel(res.sessionId); // aborts the writer, deletes partial
    await body.close();
    await uploadFuture.catchError((_) {}); // upload ends in error, that's fine

    expect(File(p.join(saveDir.path, 'partial.bin')).existsSync(), isFalse);
    expect(manager.hasActiveSession, isFalse);

    // A new session is now allowed.
    final prep2 = await sender.prepareUpload({'g': _fileDto('g', 'ok.bin', 3)});
    expect(prep2.statusCode, 200);
    await prep2.drain<void>();
  });

  test('collision-safe naming: same name twice keeps both', () async {
    Future<void> send(String content) async {
      final bytes = utf8.encode(content);
      final files = {'f': _fileDto('f', 'dup.txt', bytes.length)};
      final prep = await sender.prepareUpload(files);
      final res = PrepareUploadResponse.fromJson(
        jsonDecode(await prep.transform(utf8.decoder).join())
            as Map<String, dynamic>,
      );
      await sender.upload(res.sessionId, 'f', res.files['f']!, bytes);
    }

    await send('first');
    await send('second');

    final names = saveDir
        .listSync()
        .map((e) => p.basename(e.path))
        .toList()
      ..sort();
    expect(names, containsAll(<String>['dup.txt', 'dup (1).txt']));
  });
}
