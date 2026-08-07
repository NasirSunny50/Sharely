import 'dart:async';
import 'dart:io';

import 'package:sharely/core/constants.dart';
import 'package:sharely/core/logger.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/server/download_session_manager.dart';
import 'package:sharely/protocol/server/routes/cancel_route.dart';
import 'package:sharely/protocol/server/routes/download_route.dart';
import 'package:sharely/protocol/server/routes/info_route.dart';
import 'package:sharely/protocol/server/routes/prepare_download_route.dart';
import 'package:sharely/protocol/server/routes/prepare_upload_route.dart';
import 'package:sharely/protocol/server/routes/register_route.dart';
import 'package:sharely/protocol/server/routes/upload_route.dart';
import 'package:sharely/protocol/server/routes/web_route.dart';
import 'package:sharely/protocol/server/session_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// The LocalSend HTTP(S) server the **receiver** runs (§6.4). This Phase-2
/// skeleton serves `/info` and `/register`; upload/download routes are added in
/// later phases.
///
/// Pure Dart (`dart:io` + shelf), no Flutter imports. The device identity and
/// discovery reply behavior are injected so the server has no UI coupling.
class SharelyHttpServer {
  SharelyHttpServer({
    required this.deviceInfo,
    this.securityContext,
    this.port = SharelyConstants.defaultPort,
    InternetAddress? address,
    RegisterHandler? onRegister,
    this.receiveManager,
    this.downloadManager,
  })  : address = address ?? InternetAddress.anyIPv4,
        _onRegister = onRegister;

  static const _tag = 'HttpServer';

  /// This device's info, returned by `/info` and `/register`.
  DeviceInfo deviceInfo;

  /// When non-null the server runs HTTPS; when null it runs plain HTTP (used by
  /// browser/reverse mode, §6.5).
  final SecurityContext? securityContext;

  final int port;
  final InternetAddress address;

  /// Called when a peer POSTs its info to `/register`, so the discovery layer
  /// can record the peer. Returns nothing; the response is always this device's
  /// info per spec.
  final RegisterHandler? _onRegister;

  /// When set, the receive routes (prepare-upload, upload, cancel) are served.
  final ReceiveSessionManager? receiveManager;

  /// When set, the reverse/browser-mode routes (web page, prepare-download,
  /// download) are served. Browser mode must run on plain HTTP (§6.5), so this
  /// is used with `securityContext == null`.
  final DownloadSessionManager? downloadManager;

  HttpServer? _server;

  bool get isRunning => _server != null;

  /// The actually-bound port (useful when constructed with port 0 in tests).
  int? get boundPort => _server?.port;

  /// Whether the server is currently serving HTTPS.
  bool get isHttps => securityContext != null;

  /// Builds the shelf router. Exposed for unit testing without binding a
  /// socket.
  Handler buildHandler() {
    const base = SharelyConstants.apiBase;
    final router = Router()
      ..get('$base/info', (Request r) {
        return handleInfo(deviceInfo);
      })
      ..post('$base/register', (Request r) {
        return handleRegister(r, deviceInfo, _onRegister);
      });

    final manager = receiveManager;
    if (manager != null) {
      router
        ..post('$base/prepare-upload', (Request r) {
          return handlePrepareUpload(r, manager, _remoteIp(r));
        })
        ..post('$base/upload', (Request r) {
          return handleUpload(r, manager, _remoteIp(r));
        })
        ..post('$base/cancel', (Request r) {
          return handleCancel(r, manager);
        });
    }

    final download = downloadManager;
    if (download != null) {
      router
        ..get('/', (Request r) => handleWebPage(r, download))
        ..post('$base/prepare-download', (Request r) {
          return handlePrepareDownload(r, download);
        })
        ..get('$base/download', (Request r) {
          return handleDownload(r, download);
        });
    }

    return const Pipeline()
        .addMiddleware(_logRequests())
        .addHandler(router.call);
  }

  /// Binds the socket and starts serving. Idempotent-ish: throws if already
  /// running.
  Future<void> start() async {
    if (_server != null) {
      throw StateError('Server already running on port $port');
    }
    _server = await shelf_io.serve(
      buildHandler(),
      address,
      port,
      securityContext: securityContext,
    );
    // Do not compress: bodies are already-compressed files most of the time,
    // and streaming raw bytes is the contract (§6.4.2).
    _server!.autoCompress = false;
    SharelyLogger.instance.i(
      _tag,
      'Serving ${isHttps ? 'https' : 'http'} on ${address.address}:$port',
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    SharelyLogger.instance.i(_tag, 'Server stopped');
  }

  /// Extracts the remote IP of the connection for session/IP validation
  /// (§6.4.2). shelf_io exposes the underlying [HttpConnectionInfo] here.
  static String _remoteIp(Request request) {
    final conn = request.context['shelf.io.connection_info'];
    if (conn is HttpConnectionInfo) {
      return conn.remoteAddress.address;
    }
    return '';
  }

  Middleware _logRequests() => (inner) {
        return (Request request) async {
          final response = await inner(request);
          SharelyLogger.instance.d(
            _tag,
            '${request.method} ${request.requestedUri.path} '
            '-> ${response.statusCode}',
          );
          return response;
        };
      };
}
