import 'package:meta/meta.dart';
import 'package:sharely/protocol/models/device_info.dart';

/// How a device was discovered — used for diagnostics and to prefer the more
/// reliable source when the same peer is seen twice.
enum DiscoverySource { multicast, httpRegister, subnetScan }

/// A peer discovered on the local network: its advertised [info], the [ip] we
/// reach it at, and when it was [lastSeen] (for TTL-based staleness eviction).
///
/// Identity is the [DeviceInfo.fingerprint] — the same peer seen via multicast
/// and subnet scan is one device.
@immutable
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.info,
    required this.ip,
    required this.lastSeen,
    required this.source,
  });

  final DeviceInfo info;

  /// The IP address the peer announced from / was found at.
  final String ip;

  final DateTime lastSeen;

  final DiscoverySource source;

  String get fingerprint => info.fingerprint;

  /// The base URL for this peer's API, honoring its advertised protocol/port.
  String get baseUrl => '${info.protocol.wire}://$ip:${info.port}';

  bool isStale(DateTime now, Duration ttl) =>
      now.difference(lastSeen) > ttl;

  DiscoveredDevice copyWith({
    DeviceInfo? info,
    String? ip,
    DateTime? lastSeen,
    DiscoverySource? source,
  }) {
    return DiscoveredDevice(
      info: info ?? this.info,
      ip: ip ?? this.ip,
      lastSeen: lastSeen ?? this.lastSeen,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoveredDevice &&
      other.fingerprint == fingerprint &&
      other.ip == ip &&
      other.info == info &&
      other.lastSeen == lastSeen &&
      other.source == source;

  @override
  int get hashCode => Object.hash(fingerprint, ip, info, lastSeen, source);

  @override
  String toString() =>
      'DiscoveredDevice(${info.alias} @ $ip, ${source.name}, '
      'fp: ${fingerprint.substring(0, fingerprint.length.clamp(0, 8))})';
}
