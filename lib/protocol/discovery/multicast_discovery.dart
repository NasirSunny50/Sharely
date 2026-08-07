import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sharely/core/constants.dart';
import 'package:sharely/core/logger.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';
import 'package:sharely/protocol/discovery/discovery_service.dart';
import 'package:sharely/protocol/models/device_info.dart';

/// Called to send the preferred HTTP reply to an announcing peer: POST our
/// info to their `/api/localsend/v2/register` (§6.3.1). Supplied by the app so
/// this class stays free of an HTTP-client dependency.
typedef PeerRegistrar = Future<void> Function(DeviceInfo peer, String ip);

/// UDP multicast discovery (§6.3.1): announce on start, listen for peers, and
/// reply to their announcements. Pure Dart (`dart:io` `RawDatagramSocket`).
///
/// Reply policy per spec:
/// - **Preferred:** HTTP POST to the announcer's `/register` (via [registrar]).
/// - **Fallback:** a multicast datagram with `announce: false`.
/// A reply is only sent when the incoming datagram has `announce: true`,
/// otherwise announcements would loop forever. Datagrams whose fingerprint
/// equals ours are ignored.
class MulticastDiscovery {
  MulticastDiscovery({
    required this.localDevice,
    required this.discovery,
    this.registrar,
    this.port = SharelyConstants.defaultPort,
    this.group = SharelyConstants.multicastGroup,
  });

  static const _tag = 'Multicast';

  /// Our own device info, sent in announcements and replies.
  DeviceInfo localDevice;

  /// Registry that records discovered peers.
  final DiscoveryService discovery;

  /// Preferred (HTTP) reply mechanism. When null, only the multicast fallback
  /// reply is used.
  final PeerRegistrar? registrar;

  final int port;
  final String group;

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _sub;

  bool get isRunning => _socket != null;

  /// Binds the multicast socket, joins the group, and begins listening. Sends
  /// an initial announcement. Returns false if binding failed (caller should
  /// fall back to subnet scan).
  Future<bool> start() async {
    if (_socket != null) return true;
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
      )
        ..readEventsEnabled = true
        ..multicastLoopback = false;
      try {
        socket.joinMulticast(InternetAddress(group));
      } on Object catch (e) {
        // Some interfaces refuse the join; log and continue — we can still
        // receive unicast register replies and the app can scan.
        SharelyLogger.instance.w(_tag, 'joinMulticast failed: $e');
      }
      _socket = socket;
      _sub = socket.listen(_onEvent);
      await announce();
      SharelyLogger.instance.i(_tag, 'Listening on $group:$port');
      return true;
    } on Object catch (e) {
      SharelyLogger.instance.e(_tag, 'bind failed: $e');
      return false;
    }
  }

  /// Sends an announcement inviting replies (`announce: true`).
  Future<void> announce() async {
    _send(localDevice.toAnnouncement(announce: true));
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(utf8.decode(datagram.data));
      if (decoded is! Map<String, dynamic>) return;
      json = decoded;
    } on Object {
      return; // ignore malformed datagrams
    }

    final peer = DeviceInfo.fromJson(json);
    if (peer.fingerprint.isEmpty ||
        peer.fingerprint == localDevice.fingerprint) {
      return; // ignore self (§6.3.1)
    }

    final ip = datagram.address.address;
    discovery.onDeviceSeen(peer, ip, source: DiscoverySource.multicast);

    // Only reply to announcements (announce:true), never to replies.
    final isAnnounce = json['announce'] == true;
    if (isAnnounce) {
      unawaited(_reply(peer, ip));
    }
  }

  Future<void> _reply(DeviceInfo peer, String ip) async {
    final registrar = this.registrar;
    if (registrar != null) {
      try {
        await registrar(peer, ip);
        return; // preferred path succeeded
      } on Object catch (e) {
        SharelyLogger.instance.w(_tag, 'HTTP register reply failed: $e');
        // fall through to multicast fallback
      }
    }
    _send(localDevice.toAnnouncement(announce: false));
  }

  void _send(Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.send(
        utf8.encode(jsonEncode(payload)),
        InternetAddress(group),
        port,
      );
    } on Object catch (e) {
      SharelyLogger.instance.w(_tag, 'send failed: $e');
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      _socket?.leaveMulticast(InternetAddress(group));
    } on Object catch (_) {}
    _socket?.close();
    _socket = null;
    SharelyLogger.instance.i(_tag, 'Stopped');
  }
}
