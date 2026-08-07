import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';

void main() {
  group('DeviceType.fromWire', () {
    test('parses each known value', () {
      expect(DeviceType.fromWire('mobile'), DeviceType.mobile);
      expect(DeviceType.fromWire('desktop'), DeviceType.desktop);
      expect(DeviceType.fromWire('web'), DeviceType.web);
      expect(DeviceType.fromWire('headless'), DeviceType.headless);
      expect(DeviceType.fromWire('server'), DeviceType.server);
    });

    test('falls back to desktop for null and unknown values', () {
      expect(DeviceType.fromWire(null), DeviceType.desktop);
      expect(DeviceType.fromWire('toaster'), DeviceType.desktop);
      expect(DeviceType.fromWire(''), DeviceType.desktop);
      expect(DeviceType.fromWire('Mobile'), DeviceType.desktop); // case-sensitive
    });
  });

  group('Protocol.fromWire', () {
    test('parses https, defaults everything else to http', () {
      expect(Protocol.fromWire('https'), Protocol.https);
      expect(Protocol.fromWire('http'), Protocol.http);
      expect(Protocol.fromWire(null), Protocol.http);
      expect(Protocol.fromWire('ftp'), Protocol.http);
    });
  });

  group('DeviceInfo', () {
    test('round-trips a full payload', () {
      const original = DeviceInfo(
        alias: 'Nice Orange',
        version: '2.0',
        deviceModel: 'Samsung',
        deviceType: DeviceType.mobile,
        fingerprint: 'abc123',
        port: 53317,
        protocol: Protocol.https,
        download: true,
      );
      final decoded = DeviceInfo.fromJson(original.toJson());
      expect(decoded, original);
    });

    test('parses a real LocalSend announce datagram with extra fields', () {
      // Captured shape from §6.3.1 plus an unknown extra field.
      final json = <String, dynamic>{
        'alias': 'Nice Orange',
        'version': '2.0',
        'deviceModel': 'Samsung',
        'deviceType': 'mobile',
        'fingerprint': 'random string',
        'port': 53317,
        'protocol': 'https',
        'download': true,
        'announce': true,
        'someFutureField': 'ignored',
      };
      final info = DeviceInfo.fromJson(json);
      expect(info.alias, 'Nice Orange');
      expect(info.deviceType, DeviceType.mobile);
      expect(info.protocol, Protocol.https);
      expect(info.download, true);
      expect(info.port, 53317);
    });

    test('nullable deviceModel and defaults on a minimal payload', () {
      final info = DeviceInfo.fromJson(<String, dynamic>{
        'alias': 'Bare',
        'version': '2.0',
        'fingerprint': 'f',
        'port': 53317,
        'protocol': 'http',
      });
      expect(info.deviceModel, isNull);
      expect(info.deviceType, DeviceType.desktop); // fallback
      expect(info.download, false); // default
    });

    test('unknown deviceType in a payload falls back to desktop', () {
      final info = DeviceInfo.fromJson(<String, dynamic>{
        'alias': 'X',
        'version': '2.0',
        'deviceType': 'quantum-fridge',
        'fingerprint': 'f',
        'port': 53317,
        'protocol': 'https',
      });
      expect(info.deviceType, DeviceType.desktop);
    });

    test('toJson emits deviceModel as explicit null when absent', () {
      const info = DeviceInfo(
        alias: 'X',
        version: '2.0',
        fingerprint: 'f',
        port: 53317,
        protocol: Protocol.https,
      );
      final json = info.toJson();
      expect(json.containsKey('deviceModel'), true);
      expect(json['deviceModel'], isNull);
    });

    test('toAnnouncement adds the announce flag', () {
      const info = DeviceInfo(
        alias: 'X',
        version: '2.0',
        fingerprint: 'f',
        port: 53317,
        protocol: Protocol.https,
      );
      expect(info.toAnnouncement(announce: true)['announce'], true);
      expect(info.toAnnouncement(announce: false)['announce'], false);
    });

    test('copyWith can null out deviceModel', () {
      const info = DeviceInfo(
        alias: 'X',
        version: '2.0',
        deviceModel: 'Pixel',
        fingerprint: 'f',
        port: 53317,
        protocol: Protocol.https,
      );
      expect(info.copyWith(deviceModel: null).deviceModel, isNull);
      expect(info.copyWith(alias: 'Y').deviceModel, 'Pixel'); // untouched
    });

    test('port given as a JSON number of non-int type is coerced', () {
      final info = DeviceInfo.fromJson(<String, dynamic>{
        'alias': 'X',
        'version': '2.0',
        'fingerprint': 'f',
        'port': 53317.0,
        'protocol': 'https',
      });
      expect(info.port, 53317);
    });
  });
}
