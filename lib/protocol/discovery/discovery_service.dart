import 'dart:async';

import 'package:sharely/core/constants.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';
import 'package:sharely/protocol/models/device_info.dart';

/// In-memory registry of nearby devices, merged from all discovery sources
/// (multicast, HTTP register replies, subnet scan) and deduped by fingerprint.
///
/// Pure Dart — no sockets here, so it is fully unit-testable. The socket-facing
/// multicast and subnet-scan discoverers push into this via [onDeviceSeen].
/// Handles self-fingerprint filtering (§6.3.1) and TTL staleness eviction.
class DiscoveryService {
  DiscoveryService({
    required this.ownFingerprint,
    this.staleTtl = SharelyConstants.deviceStaleTtl,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Our own fingerprint; datagrams/replies with this fingerprint are ignored
  /// to avoid self-discovery (§6.3.1).
  final String ownFingerprint;

  /// How long a device stays listed without being seen again.
  final Duration staleTtl;

  final DateTime Function() _clock;

  final Map<String, DiscoveredDevice> _devices = {};
  final StreamController<List<DiscoveredDevice>> _controller =
      StreamController<List<DiscoveredDevice>>.broadcast();

  Timer? _evictionTimer;

  /// Broadcast stream of the current device list, emitted on every change.
  Stream<List<DiscoveredDevice>> get devices => _controller.stream;

  /// A snapshot of the currently-known (non-stale) devices.
  List<DiscoveredDevice> get snapshot {
    _evictStale();
    return _sorted();
  }

  /// Records a peer sighting. Ignores our own fingerprint. When the same
  /// fingerprint is already known, updates its info/ip/lastSeen. Returns true
  /// if this was a new device or a changed one (i.e. the list changed).
  bool onDeviceSeen(
    DeviceInfo info,
    String ip, {
    required DiscoverySource source,
  }) {
    if (info.fingerprint.isEmpty || info.fingerprint == ownFingerprint) {
      return false;
    }

    final now = _clock();
    final existing = _devices[info.fingerprint];
    final changed =
        existing == null || existing.ip != ip || existing.info != info;
    _devices[info.fingerprint] = DiscoveredDevice(
      info: info,
      ip: ip,
      lastSeen: now,
      source: source,
    );
    // Emit on every sighting: even when identity is unchanged, lastSeen was
    // refreshed and any staleness countdown must reset for observers.
    _emit();
    return changed;
  }

  /// Removes a device by fingerprint (e.g. on an explicit "goodbye" or when a
  /// transfer proves it unreachable).
  void remove(String fingerprint) {
    if (_devices.remove(fingerprint) != null) _emit();
  }

  /// Starts periodic staleness eviction. Safe to call once; no-op if running.
  void startEviction({Duration interval = const Duration(seconds: 2)}) {
    _evictionTimer ??= Timer.periodic(interval, (_) => _evictStale());
  }

  void _evictStale() {
    final now = _clock();
    final before = _devices.length;
    _devices.removeWhere((_, d) => d.isStale(now, staleTtl));
    if (_devices.length != before) _emit();
  }

  List<DiscoveredDevice> _sorted() {
    final list = _devices.values.toList()
      ..sort((a, b) => a.info.alias.toLowerCase().compareTo(
            b.info.alias.toLowerCase(),
          ));
    return List.unmodifiable(list);
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_sorted());
  }

  Future<void> dispose() async {
    _evictionTimer?.cancel();
    _evictionTimer = null;
    await _controller.close();
  }
}
