import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sharely/core/logger.dart';
import 'package:sharely/features/settings/settings_controller.dart';
import 'package:sharely/platform/notifications.dart';
import 'package:sharely/protocol/client/send_service.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';
import 'package:sharely/protocol/discovery/discovery_service.dart';
import 'package:sharely/protocol/discovery/http_discovery.dart';
import 'package:sharely/protocol/discovery/multicast_discovery.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';
import 'package:sharely/protocol/models/prepare_upload_dto.dart';
import 'package:sharely/protocol/models/session.dart';
import 'package:sharely/protocol/security/certificate_manager.dart';
import 'package:sharely/protocol/server/download_session_manager.dart';
import 'package:sharely/protocol/server/http_server.dart';
import 'package:sharely/protocol/server/session_manager.dart';

/// A pending incoming request awaiting the user's accept/partial/reject.
@immutable
class IncomingRequest {
  const IncomingRequest({required this.request, required this.remoteIp});
  final PrepareUploadRequest request;
  final String remoteIp;
}

/// Aggregate UI state for the network layer.
@immutable
class NetworkState {
  const NetworkState({
    this.devices = const [],
    this.networkName,
    this.localIp,
    this.hasWifi = true,
    this.incoming,
    this.receiveSession,
    this.ready = false,
    this.browserUrl,
    this.browserConnections = 0,
  });

  final List<DiscoveredDevice> devices;
  final String? networkName;
  final String? localIp;
  final bool hasWifi;
  final IncomingRequest? incoming;
  final Session? receiveSession;
  final bool ready;

  /// When hosting browser mode, the URL receivers open; null otherwise.
  final String? browserUrl;

  /// How many receivers have opened the browser-mode share.
  final int browserConnections;

  NetworkState copyWith({
    List<DiscoveredDevice>? devices,
    String? networkName,
    String? localIp,
    bool? hasWifi,
    Object? incoming = _sentinel,
    Object? receiveSession = _sentinel,
    bool? ready,
    Object? browserUrl = _sentinel,
    int? browserConnections,
  }) {
    return NetworkState(
      devices: devices ?? this.devices,
      networkName: networkName ?? this.networkName,
      localIp: localIp ?? this.localIp,
      hasWifi: hasWifi ?? this.hasWifi,
      incoming: identical(incoming, _sentinel)
          ? this.incoming
          : incoming as IncomingRequest?,
      receiveSession: identical(receiveSession, _sentinel)
          ? this.receiveSession
          : receiveSession as Session?,
      ready: ready ?? this.ready,
      browserUrl: identical(browserUrl, _sentinel)
          ? this.browserUrl
          : browserUrl as String?,
      browserConnections: browserConnections ?? this.browserConnections,
    );
  }
}

const Object _sentinel = Object();

/// Owns the live protocol services and exposes their state to the UI. On
/// [init] it generates/loads the TLS identity, starts the HTTPS server with the
/// receive routes, and begins multicast discovery. The accept decision for
/// incoming transfers is bridged to the UI via a [Completer].
class NetworkController extends StateNotifier<NetworkState> {
  NetworkController(this._ref) : super(const NetworkState());

  static const _tag = 'Network';

  final Ref _ref;

  DiscoveryService? _discovery;
  MulticastDiscovery? _multicast;
  HttpDiscovery? _httpDiscovery;
  SharelyHttpServer? _server;
  ReceiveSessionManager? _receiveManager;
  SendService? _sendService;
  DeviceInfo? _localDevice;

  DownloadSessionManager? _downloadManager;
  SharelyHttpServer? _browserServer;
  StreamSubscription<int>? _browserConnSub;

  Completer<Set<String>>? _pendingAccept;
  StreamSubscription<List<DiscoveredDevice>>? _devicesSub;
  StreamSubscription<Session>? _receiveSub;

  SendService? get sendService => _sendService;
  DeviceInfo? get localDevice => _localDevice;

  /// Best-effort startup. Failures (e.g. permissions not yet granted) are
  /// logged; the UI degrades to the manual/offline states.
  Future<void> init() async {
    try {
      final settings = _ref.read(settingsProvider);

      final dir = await getApplicationSupportDirectory();
      final certMgr = CertificateManager(
        storageDir: Directory(p.join(dir.path, 'identity')),
      );
      await certMgr.ensureInitialized();

      final saveDir = settings.saveDirPath != null
          ? Directory(settings.saveDirPath!)
          : Directory(p.join((await _downloadsDir()).path, 'Sharely'));

      _localDevice = DeviceInfo(
        alias: settings.alias,
        version: '2.0',
        deviceModel: defaultTargetPlatform.name,
        deviceType: _deviceType(),
        fingerprint: certMgr.fingerprint,
        port: settings.port,
        protocol: Protocol.https,
      );

      _discovery = DiscoveryService(ownFingerprint: certMgr.fingerprint)
        ..startEviction();
      _receiveManager = ReceiveSessionManager(
        saveDir: saveDir,
        acceptResolver: _resolveAccept,
      )..pinGuard.pin = settings.pin;

      _server = SharelyHttpServer(
        deviceInfo: _localDevice!,
        securityContext: certMgr.securityContext,
        port: settings.port,
        receiveManager: _receiveManager,
        onRegister: (peer) => _discovery!.onDeviceSeen(
          peer,
          '', // ip filled from datagram elsewhere; register echo is best-effort
          source: DiscoverySource.httpRegister,
        ),
      );
      await _server!.start();

      _multicast = MulticastDiscovery(
        localDevice: _localDevice!,
        discovery: _discovery!,
        port: settings.port,
      );
      await _multicast!.start();

      _httpDiscovery = HttpDiscovery(
        localDevice: _localDevice!,
        discovery: _discovery!,
        port: settings.port,
      );
      _sendService = SendService(localDevice: _localDevice!);

      _devicesSub = _discovery!.devices.listen(
        (devices) => state = state.copyWith(devices: devices),
      );
      _receiveSub = _receiveManager!.sessionUpdates.listen((session) {
        state = state.copyWith(receiveSession: session);
        if (session.state == SessionState.completed) {
          unawaited(NotificationService.instance
              .showComplete(session.files.length, 'Downloads/Sharely'));
        } else if (session.state == SessionState.failed) {
          unawaited(NotificationService.instance.showFailed('Transfer failed'));
        }
      });

      await _refreshNetworkInfo();
      state = state.copyWith(ready: true);
      SharelyLogger.instance.i(_tag, 'Network ready as ${settings.alias}');
    } on Object catch (e, st) {
      SharelyLogger.instance.e(_tag, 'init failed: $e\n$st');
      state = state.copyWith(hasWifi: false);
    }
  }

  Future<Set<String>> _resolveAccept(
    PrepareUploadRequest request,
    String remoteIp,
  ) async {
    final settings = _ref.read(settingsProvider);
    // Quick Save / favourites auto-accept everything.
    if (settings.quickSave || !settings.askBeforeAccepting) {
      return request.files.keys.toSet();
    }
    final completer = Completer<Set<String>>();
    _pendingAccept = completer;
    state = state.copyWith(
      incoming: IncomingRequest(request: request, remoteIp: remoteIp),
    );
    unawaited(NotificationService.instance
        .showIncoming(request.info.alias, request.files.length));
    return completer.future;
  }

  /// Called by the incoming-request sheet: accept the given file ids (empty to
  /// reject).
  void respondToIncoming(Set<String> acceptedIds) {
    _pendingAccept?.complete(acceptedIds);
    _pendingAccept = null;
    state = state.copyWith(incoming: null);
  }

  /// Starts hosting [files] for browser/reverse mode (§6.5) on a **plain-HTTP**
  /// server (browsers reject self-signed certs), on `port + 1` so it doesn't
  /// clash with the main HTTPS server. Returns the URL receivers open.
  Future<String?> startBrowserMode(List<DownloadableFile> files) async {
    final self = _localDevice;
    final ip = state.localIp;
    if (self == null || ip == null) return null;
    await stopBrowserMode();

    final browserPort = self.port + 1;
    final manager = DownloadSessionManager(
      selfInfo: self.copyWith(protocol: Protocol.http, download: true),
    )..host(files);
    _downloadManager = manager;

    _browserServer = SharelyHttpServer(
      deviceInfo: self,
      port: browserPort,
      downloadManager: manager,
    );
    await _browserServer!.start();

    _browserConnSub = manager.connectionUpdates.listen(
      (count) => state = state.copyWith(browserConnections: count),
    );

    final url = 'http://$ip:$browserPort';
    state = state.copyWith(browserUrl: url, browserConnections: 0);
    return url;
  }

  Future<void> stopBrowserMode() async {
    await _browserConnSub?.cancel();
    _browserConnSub = null;
    await _browserServer?.stop();
    _browserServer = null;
    await _downloadManager?.dispose();
    _downloadManager = null;
    state = state.copyWith(browserUrl: null, browserConnections: 0);
  }

  /// Manual subnet scan (§6.3.2), behind the "Scan network" button.
  Future<void> scanNetwork() async {
    final ip = state.localIp;
    if (ip != null && _httpDiscovery != null) {
      await _httpDiscovery!.scan(ip);
    }
  }

  Future<void> _refreshNetworkInfo() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      final name = await info.getWifiName();
      state = state.copyWith(
        localIp: ip,
        networkName: name?.replaceAll('"', ''),
        hasWifi: ip != null,
      );
    } on Object catch (e) {
      SharelyLogger.instance.w(_tag, 'network info failed: $e');
    }
  }

  Future<Directory> _downloadsDir() async {
    try {
      final d = await getDownloadsDirectory();
      if (d != null) return d;
    } on Object {
      // not available on all platforms
    }
    return getApplicationDocumentsDirectory();
  }

  DeviceType _deviceType() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return DeviceType.mobile;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return DeviceType.desktop;
    }
  }

  @override
  void dispose() {
    unawaited(_devicesSub?.cancel());
    unawaited(_receiveSub?.cancel());
    unawaited(_browserConnSub?.cancel());
    unawaited(_browserServer?.stop());
    unawaited(_downloadManager?.dispose());
    unawaited(_multicast?.stop());
    unawaited(_server?.stop());
    unawaited(_discovery?.dispose());
    unawaited(_receiveManager?.dispose());
    unawaited(_sendService?.dispose());
    super.dispose();
  }
}

final networkControllerProvider =
    StateNotifierProvider<NetworkController, NetworkState>((ref) {
  return NetworkController(ref);
});
