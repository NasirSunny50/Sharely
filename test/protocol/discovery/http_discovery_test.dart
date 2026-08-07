import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/discovery/discovery_service.dart';
import 'package:sharely/protocol/discovery/http_discovery.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';
import 'package:sharely/protocol/server/http_server.dart';

const _local = DeviceInfo(
  alias: 'Scanner',
  version: '2.0',
  deviceType: DeviceType.desktop,
  fingerprint: 'scanner-fp',
  port: 53317,
  protocol: Protocol.http, // scan over plain http in the test
  download: false,
);

void main() {
  group('subnetHosts', () {
    test('enumerates .1–.254 excluding self', () {
      final hosts = HttpDiscovery.subnetHosts('192.168.1.42');
      expect(hosts.length, 253); // 254 minus self
      expect(hosts, contains('192.168.1.1'));
      expect(hosts, contains('192.168.1.254'));
      expect(hosts, isNot(contains('192.168.1.42')));
      expect(hosts.every((h) => h.startsWith('192.168.1.')), isTrue);
    });

    test('returns empty for a malformed IP', () {
      expect(HttpDiscovery.subnetHosts('not.an.ip'), isEmpty);
      expect(HttpDiscovery.subnetHosts('10.0.0'), isEmpty);
    });
  });

  group('end-to-end subnet scan against a live /register (§6.3.2)', () {
    test('discovers a peer server on the loopback /24', () async {
      // A peer server on a fixed port, reachable at 127.0.0.1.
      const peerPort = 53410;
      final server = SharelyHttpServer(
        deviceInfo: const DeviceInfo(
          alias: 'Peer Server',
          version: '2.0',
          deviceType: DeviceType.mobile,
          fingerprint: 'peer-server-fp',
          port: peerPort,
          protocol: Protocol.http,
        ),
        port: peerPort,
      );
      await server.start();
      addTearDown(server.stop);

      final discovery = DiscoveryService(ownFingerprint: _local.fingerprint);
      addTearDown(discovery.dispose);

      // Scan the loopback /24 from .2, so .1 (our server) is probed. The other
      // 252 addresses refuse quickly.
      final scanner = HttpDiscovery(
        localDevice: _local,
        discovery: discovery,
        port: peerPort,
      );
      await scanner.scan('127.0.0.2');

      final found = discovery.snapshot;
      // Deduped to a single device despite many loopback addresses reaching the
      // same server (127.0.0.0/8 is all loopback), keyed by fingerprint.
      expect(found.length, 1);
      expect(found.single.fingerprint, 'peer-server-fp');
      expect(found.single.ip, startsWith('127.0.0.'));
      expect(found.single.info.alias, 'Peer Server');
    }, tags: ['slow']);
  });
}
