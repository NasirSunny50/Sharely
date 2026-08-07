@Tags(['slow'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/discovery/discovery_service.dart';
import 'package:sharely/protocol/discovery/multicast_discovery.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';

// A dedicated port so the test never clashes with a running Sharely/LocalSend.
const _port = 53421;
const _group = '224.0.0.167';

const _local = DeviceInfo(
  alias: 'Local',
  version: '2.0',
  deviceType: DeviceType.desktop,
  fingerprint: 'local-fp',
  port: _port,
  protocol: Protocol.https,
);

void main() {
  test('records a peer from a real multicast announce datagram', () async {
    final discovery = DiscoveryService(ownFingerprint: _local.fingerprint);
    addTearDown(discovery.dispose);

    final mc = MulticastDiscovery(
      localDevice: _local,
      discovery: discovery,
      port: _port,
      group: _group,
    );
    final bound = await mc.start();
    if (!bound) {
      markTestSkipped('Multicast bind not permitted in this environment');
      return;
    }
    addTearDown(mc.stop);

    // A separate socket plays the role of a remote peer announcing itself.
    final sender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
      ..multicastLoopback = true; // so our local listener receives it
    addTearDown(sender.close);

    final peer = const DeviceInfo(
      alias: 'Remote Peer',
      version: '2.0',
      deviceType: DeviceType.mobile,
      fingerprint: 'remote-fp',
      port: _port,
      protocol: Protocol.https,
    ).toAnnouncement(announce: true);

    // Send a few times; UDP is lossy and the first packet can race the join.
    for (var i = 0; i < 5; i++) {
      sender.send(
        utf8.encode(jsonEncode(peer)),
        InternetAddress(_group),
        _port,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (discovery.snapshot.isNotEmpty) break;
    }

    if (discovery.snapshot.isEmpty) {
      markTestSkipped('No multicast delivery in this environment');
      return;
    }

    final found = discovery.snapshot.single;
    expect(found.fingerprint, 'remote-fp');
    expect(found.info.alias, 'Remote Peer');
    expect(found.info.deviceType, DeviceType.mobile);
  });

  test('a self-fingerprinted datagram is ignored (no self-discovery)',
      () async {
    final discovery = DiscoveryService(ownFingerprint: _local.fingerprint);
    addTearDown(discovery.dispose);

    final mc = MulticastDiscovery(
      localDevice: _local,
      discovery: discovery,
      port: _port,
      group: _group,
    );
    final bound = await mc.start();
    if (!bound) {
      markTestSkipped('Multicast bind not permitted in this environment');
      return;
    }
    addTearDown(mc.stop);

    final sender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
      ..multicastLoopback = true;
    addTearDown(sender.close);

    // Announce with OUR fingerprint — must be ignored.
    final selfEcho = _local.toAnnouncement(announce: true);
    for (var i = 0; i < 5; i++) {
      sender.send(
        utf8.encode(jsonEncode(selfEcho)),
        InternetAddress(_group),
        _port,
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    expect(discovery.snapshot, isEmpty);
  });
}
