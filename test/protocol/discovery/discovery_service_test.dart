import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';
import 'package:sharely/protocol/discovery/discovery_service.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';

DeviceInfo _peer(String fp, {String alias = 'Peer'}) => DeviceInfo(
      alias: alias,
      version: '2.0',
      fingerprint: fp,
      port: 53317,
      protocol: Protocol.https,
      deviceType: DeviceType.mobile,
    );

void main() {
  group('self-filtering', () {
    test('ignores our own fingerprint', () {
      final svc = DiscoveryService(ownFingerprint: 'me');
      final changed =
          svc.onDeviceSeen(_peer('me'), '1.2.3.4', source: DiscoverySource.multicast);
      expect(changed, isFalse);
      expect(svc.snapshot, isEmpty);
    });

    test('ignores empty fingerprint', () {
      final svc = DiscoveryService(ownFingerprint: 'me');
      svc.onDeviceSeen(_peer(''), '1.2.3.4', source: DiscoverySource.multicast);
      expect(svc.snapshot, isEmpty);
    });
  });

  group('dedupe by fingerprint', () {
    test('same fingerprint from two sources is one device', () {
      final svc = DiscoveryService(ownFingerprint: 'me');
      svc.onDeviceSeen(_peer('a'), '10.0.0.5',
          source: DiscoverySource.multicast);
      svc.onDeviceSeen(_peer('a'), '10.0.0.5',
          source: DiscoverySource.subnetScan);
      expect(svc.snapshot.length, 1);
    });

    test('different fingerprints are distinct devices, sorted by alias', () {
      final svc = DiscoveryService(ownFingerprint: 'me');
      svc.onDeviceSeen(_peer('b', alias: 'Zed'), '10.0.0.6',
          source: DiscoverySource.multicast);
      svc.onDeviceSeen(_peer('a', alias: 'Amy'), '10.0.0.5',
          source: DiscoverySource.multicast);
      final list = svc.snapshot;
      expect(list.map((d) => d.info.alias), ['Amy', 'Zed']);
    });

    test('a changed IP updates the existing entry', () {
      final svc = DiscoveryService(ownFingerprint: 'me');
      svc.onDeviceSeen(_peer('a'), '10.0.0.5',
          source: DiscoverySource.multicast);
      final changed = svc.onDeviceSeen(_peer('a'), '10.0.0.9',
          source: DiscoverySource.multicast);
      expect(changed, isTrue);
      expect(svc.snapshot.single.ip, '10.0.0.9');
    });
  });

  group('TTL eviction', () {
    test('evicts a device once it exceeds the TTL', () {
      var now = DateTime(2026);
      final svc = DiscoveryService(
        ownFingerprint: 'me',
        staleTtl: const Duration(seconds: 5),
        clock: () => now,
      );
      svc.onDeviceSeen(_peer('a'), '10.0.0.5',
          source: DiscoverySource.multicast);
      expect(svc.snapshot.length, 1);

      now = now.add(const Duration(seconds: 6)); // past TTL
      expect(svc.snapshot, isEmpty);
    });

    test('a fresh sighting resets the staleness clock', () {
      var now = DateTime(2026);
      final svc = DiscoveryService(
        ownFingerprint: 'me',
        staleTtl: const Duration(seconds: 5),
        clock: () => now,
      );
      svc.onDeviceSeen(_peer('a'), '10.0.0.5',
          source: DiscoverySource.multicast);
      now = now.add(const Duration(seconds: 4));
      svc.onDeviceSeen(_peer('a'), '10.0.0.5',
          source: DiscoverySource.multicast); // refresh
      now = now.add(const Duration(seconds: 4)); // 8s since first, 4s since last
      expect(svc.snapshot.length, 1); // still fresh
    });
  });

  group('stream', () {
    test('emits the updated list on each change', () async {
      final svc = DiscoveryService(ownFingerprint: 'me');
      final emissions = <int>[];
      final sub = svc.devices.listen((list) => emissions.add(list.length));

      svc.onDeviceSeen(_peer('a'), '10.0.0.5',
          source: DiscoverySource.multicast);
      svc.onDeviceSeen(_peer('b'), '10.0.0.6',
          source: DiscoverySource.multicast);
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last, 2);
      await sub.cancel();
      await svc.dispose();
    });
  });
}
