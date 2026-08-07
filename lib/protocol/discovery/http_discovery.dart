import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sharely/core/constants.dart';
import 'package:sharely/core/logger.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';
import 'package:sharely/protocol/discovery/discovery_service.dart';
import 'package:sharely/protocol/models/device_info.dart';

/// HTTP legacy discovery (§6.3.2): the subnet-scan fallback used when multicast
/// fails. POSTs `/api/localsend/v2/register` to every host on the local /24,
/// with bounded concurrency and a short per-host timeout so the UI never hangs
/// and routers don't flag us.
///
/// Pure Dart (`dart:io`). The local IP is injected by the app (from
/// `network_info_plus`) so this class stays Flutter-free.
class HttpDiscovery {
  HttpDiscovery({
    required this.localDevice,
    required this.discovery,
    this.port = SharelyConstants.defaultPort,
    this.concurrency = SharelyConstants.subnetScanConcurrency,
    this.perHostTimeout = SharelyConstants.subnetScanTimeout,
  });

  static const _tag = 'SubnetScan';

  DeviceInfo localDevice;
  final DiscoveryService discovery;
  final int port;
  final int concurrency;
  final Duration perHostTimeout;

  bool _scanning = false;
  bool get isScanning => _scanning;

  /// Enumerates the /24 host addresses for [localIp] (`.1`–`.254`), excluding
  /// [localIp] itself. Pure and testable.
  static List<String> subnetHosts(String localIp) {
    final parts = localIp.split('.');
    if (parts.length != 4) return const [];
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
    final self = int.tryParse(parts[3]);
    final hosts = <String>[];
    for (var i = 1; i <= 254; i++) {
      if (i == self) continue;
      hosts.add('$prefix.$i');
    }
    return hosts;
  }

  /// Scans the /24 subnet of [localIp]. Completes when every host has been
  /// probed (or timed out). Discovered peers are pushed into [discovery].
  Future<void> scan(String localIp) async {
    if (_scanning) return;
    _scanning = true;
    final hosts = subnetHosts(localIp);
    SharelyLogger.instance.i(_tag, 'Scanning ${hosts.length} hosts on /24');

    final client = HttpClient()
      ..connectionTimeout = perHostTimeout
      // Peers use self-signed certs in HTTPS mode; accept them (we identify
      // by fingerprint, not by a CA chain).
      ..badCertificateCallback = (cert, host, port) => true;

    try {
      final iterator = hosts.iterator;
      final workers = List.generate(
        concurrency,
        (_) => _worker(iterator, client),
      );
      await Future.wait(workers);
    } finally {
      client.close(force: true);
      _scanning = false;
      SharelyLogger.instance.i(_tag, 'Scan complete');
    }
  }

  Future<void> _worker(Iterator<String> hosts, HttpClient client) async {
    while (true) {
      final String host;
      // Iterator access is synchronous; grab the next host atomically for this
      // single-threaded event loop.
      if (!hosts.moveNext()) return;
      host = hosts.current;
      await _probe(client, host);
    }
  }

  Future<void> _probe(HttpClient client, String host) async {
    final proto = localDevice.protocol.wire;
    final uri = Uri.parse(
      '$proto://$host:$port${SharelyConstants.apiBase}/register',
    );
    try {
      final req = await client.postUrl(uri).timeout(perHostTimeout);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(localDevice.toJson()));
      final resp = await req.close().timeout(perHostTimeout);
      if (resp.statusCode != 200) {
        await resp.drain<void>();
        return;
      }
      final body = await resp.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return;
      final peer = DeviceInfo.fromJson(decoded);
      if (peer.fingerprint.isEmpty ||
          peer.fingerprint == localDevice.fingerprint) {
        return;
      }
      discovery.onDeviceSeen(peer, host, source: DiscoverySource.subnetScan);
    } on Object {
      // Unreachable host / timeout / connection refused — expected for most
      // addresses on the subnet. Silently move on.
    }
  }
}
