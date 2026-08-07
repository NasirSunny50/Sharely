@Tags(['slow']) // starts a real TLS server
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';
import 'package:sharely/protocol/security/certificate_manager.dart';
import 'package:sharely/protocol/server/http_server.dart';

const _self = DeviceInfo(
  alias: 'Sharely Test',
  version: '2.0',
  deviceModel: 'CI',
  deviceType: DeviceType.desktop,
  fingerprint: 'self-fp',
  port: 53317,
  protocol: Protocol.https,
  download: false,
);

void main() {
  group('HTTP (plain) routes', () {
    late SharelyHttpServer server;

    setUp(() async {
      server = SharelyHttpServer(deviceInfo: _self, port: 0);
      await server.start();
    });

    tearDown(() => server.stop());

    test('GET /info returns this device info', () async {
      final json = await _getJson(
        'http://127.0.0.1:${server.boundPort}/api/localsend/v2/info',
      );
      expect(json['alias'], 'Sharely Test');
      expect(json['deviceType'], 'desktop');
      expect(json['protocol'], 'https');
    });

    test('POST /register records the peer and replies with our info', () async {
      DeviceInfo? recorded;
      final s2 = SharelyHttpServer(
        deviceInfo: _self,
        port: 0,
        onRegister: (peer) => recorded = peer,
      );
      await s2.start();
      addTearDown(s2.stop);

      final peer = DeviceInfo.fromJson(const {
        'alias': 'Peer Phone',
        'version': '2.0',
        'deviceType': 'mobile',
        'fingerprint': 'peer-fp',
        'port': 53317,
        'protocol': 'https',
      });

      final reply = await _postJson(
        'http://127.0.0.1:${s2.boundPort}/api/localsend/v2/register',
        peer.toJson(),
      );

      expect(recorded, isNotNull);
      expect(recorded!.alias, 'Peer Phone');
      expect(recorded!.deviceType, DeviceType.mobile);
      // Reply is OUR info.
      expect(reply['alias'], 'Sharely Test');
    });

    test('POST /register with invalid JSON returns 400', () async {
      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse(
          'http://127.0.0.1:${server.boundPort}/api/localsend/v2/register',
        ),
      );
      req.write('not json');
      final resp = await req.close();
      expect(resp.statusCode, 400);
      client.close();
    });
  });

  group('HTTPS with self-signed cert (§6.2)', () {
    test('served TLS cert SHA-256 equals the announced fingerprint', () async {
      final tmp = Directory.systemTemp.createTempSync('sharely_srv_tls');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final certMgr = CertificateManager(storageDir: tmp);
      await certMgr.ensureInitialized();

      final server = SharelyHttpServer(
        deviceInfo: _self.copyWith(fingerprint: certMgr.fingerprint),
        securityContext: certMgr.securityContext,
        port: 0,
      );
      await server.start();
      addTearDown(server.stop);

      expect(server.isHttps, isTrue);

      // Connect over TLS, accepting the self-signed cert, and hash what we get.
      final client = HttpClient();
      String? servedFingerprint;
      client.badCertificateCallback = (cert, host, port) {
        servedFingerprint = sha256.convert(cert.der).toString();
        return true; // accept self-signed for the test
      };
      final req = await client.getUrl(
        Uri.parse(
          'https://127.0.0.1:${server.boundPort}/api/localsend/v2/info',
        ),
      );
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      expect(resp.statusCode, 200);
      expect((jsonDecode(body) as Map<String, dynamic>)['alias'], 'Sharely Test');
      // The fingerprint the peer would compute from the TLS cert must equal the
      // one we announce.
      expect(servedFingerprint, certMgr.fingerprint);
    });
  });
}

Future<Map<String, dynamic>> _getJson(String url) async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(url));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  client.close();
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _postJson(
  String url,
  Map<String, dynamic> payload,
) async {
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse(url));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(payload));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  client.close();
  return jsonDecode(body) as Map<String, dynamic>;
}
