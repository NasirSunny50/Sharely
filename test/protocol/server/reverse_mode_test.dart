@Tags(['slow'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';
import 'package:sharely/protocol/models/file_dto.dart';
import 'package:sharely/protocol/models/prepare_download_dto.dart';
import 'package:sharely/protocol/security/pin_guard.dart';
import 'package:sharely/protocol/server/download_session_manager.dart';
import 'package:sharely/protocol/server/http_server.dart';

const _host = DeviceInfo(
  alias: 'Sharely Host',
  version: '2.0',
  deviceType: DeviceType.desktop,
  fingerprint: 'host-fp',
  port: 53317,
  protocol: Protocol.http,
  download: true,
);

Uint8List _bytes(int n, {int seed = 4}) {
  final r = Random(seed);
  final b = Uint8List(n);
  for (var i = 0; i < n; i++) {
    b[i] = r.nextInt(256);
  }
  return b;
}

DownloadableFile _file(String id, String name, Uint8List data) =>
    DownloadableFile(
      dto: FileDto(
          id: id, fileName: name, size: data.length, fileType: 'application/octet-stream'),
      openRead: () => Stream.value(data),
    );

void main() {
  late DownloadSessionManager manager;
  late SharelyHttpServer server;
  late String base;
  final client = HttpClient();

  Future<void> boot(PinGuard pin) async {
    manager = DownloadSessionManager(selfInfo: _host, pinGuard: pin);
    server = SharelyHttpServer(
      deviceInfo: _host,
      port: 0, // plain HTTP (no securityContext) — browser mode
      downloadManager: manager,
    );
    await server.start();
    base = 'http://127.0.0.1:${server.boundPort}';
  }

  tearDown(() async {
    await server.stop();
    await manager.dispose();
  });

  tearDownAll(() => client.close(force: true));

  Future<HttpClientResponse> get(String url) async =>
      (await client.getUrl(Uri.parse(url))).close();
  Future<HttpClientResponse> post(String url) async =>
      (await client.postUrl(Uri.parse(url))).close();

  test('web page lists the hosted files', () async {
    await boot(PinGuard());
    manager.host([_file('a', 'song.mp3', _bytes(1024))]);

    final resp = await get(base);
    expect(resp.statusCode, 200);
    final html = await resp.transform(utf8.decoder).join();
    expect(html, contains('song.mp3'));
    expect(html, contains('Download all'));
  });

  test('prepare-download returns session + files, download is byte-identical',
      () async {
    await boot(PinGuard());
    final data = _bytes(256 * 1024, seed: 9);
    manager.host([_file('f1', 'video.mp4', data)]);

    final prep = await post('$base/api/localsend/v2/prepare-download');
    expect(prep.statusCode, 200);
    final res = PrepareDownloadResponse.fromJson(
      jsonDecode(await prep.transform(utf8.decoder).join())
          as Map<String, dynamic>,
    );
    expect(res.files.keys, contains('f1'));

    final dl = await get(
      '$base/api/localsend/v2/download?sessionId=${res.sessionId}&fileId=f1',
    );
    expect(dl.statusCode, 200);
    expect(dl.headers.value('content-length'), '${data.length}');
    expect(dl.headers.value('content-disposition'), contains('video.mp4'));

    final received = await _collect(dl);
    expect(sha256.convert(received), sha256.convert(data));
  });

  test('download with a wrong session id is 404', () async {
    await boot(PinGuard());
    manager.host([_file('f1', 'a.bin', _bytes(16))]);
    final dl = await get(
      '$base/api/localsend/v2/download?sessionId=nope&fileId=f1',
    );
    expect(dl.statusCode, 404);
    await dl.drain<void>();
  });

  test('PIN gate: prepare-download without PIN is 401', () async {
    final pin = PinGuard()..pin = '999999';
    await boot(pin);
    manager.host([_file('f1', 'a.bin', _bytes(16))]);

    final noPin = await post('$base/api/localsend/v2/prepare-download');
    expect(noPin.statusCode, 401);
    await noPin.drain<void>();

    final withPin =
        await post('$base/api/localsend/v2/prepare-download?pin=999999');
    expect(withPin.statusCode, 200);
    await withPin.drain<void>();
  });

  test('connection count increments when a receiver opens the session',
      () async {
    await boot(PinGuard());
    manager.host([_file('f1', 'a.bin', _bytes(16))]);
    expect(manager.connectionCount, 0);
    await (await post('$base/api/localsend/v2/prepare-download')).drain<void>();
    expect(manager.connectionCount, 1);
  });
}

Future<List<int>> _collect(HttpClientResponse resp) =>
    resp.expand((chunk) => chunk).toList();
