import 'dart:async';
import 'dart:math';

import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/file_dto.dart';
import 'package:sharely/protocol/models/prepare_download_dto.dart';
import 'package:sharely/protocol/security/pin_guard.dart';

/// A file offered for reverse-download (browser mode): its [dto] plus a factory
/// [openRead] that opens a fresh byte stream each time.
class DownloadableFile {
  DownloadableFile({required this.dto, required this.openRead});
  final FileDto dto;
  final Stream<List<int>> Function() openRead;
}

/// Owns the **reverse/download** session (§6.5). Here *this* device is the host:
/// it advertises a set of files, hands out a session on `prepare-download`, and
/// streams bytes on `download`. Plain HTTP only (browsers reject self-signed
/// certs). Pure Dart.
class DownloadSessionManager {
  DownloadSessionManager({
    required this.selfInfo,
    PinGuard? pinGuard,
    Random? random,
  })  : pinGuard = pinGuard ?? PinGuard(),
        _random = random ?? Random.secure();

  DeviceInfo selfInfo;
  final PinGuard pinGuard;
  final Random _random;

  final Map<String, DownloadableFile> _files = {}; // fileId -> file
  String? _sessionId;

  final StreamController<int> _connections = StreamController<int>.broadcast();
  int _connectionCount = 0;

  /// Emits the count of receivers who have opened the session (for the
  /// "someone connected" host UI).
  Stream<int> get connectionUpdates => _connections.stream;
  int get connectionCount => _connectionCount;

  bool get isHosting => _files.isNotEmpty;
  List<FileDto> get offeredFiles =>
      _files.values.map((f) => f.dto).toList(growable: false);

  /// Begins hosting [files] for download. Returns the browser URL path base
  /// (the caller composes the full `http://ip:port`).
  void host(List<DownloadableFile> files) {
    _files
      ..clear()
      ..addEntries(files.map((f) => MapEntry(f.dto.id, f)));
    _sessionId = _randomId(16);
    _connectionCount = 0;
  }

  void stop() {
    _files.clear();
    _sessionId = null;
  }

  /// Handles `prepare-download` (§6.5). Reuses the session id on a browser
  /// refresh when [requestedSessionId] matches. Returns null with a status code
  /// on PIN failure.
  ({PrepareDownloadResponse? response, int status}) prepareDownload({
    String? requestedSessionId,
    String? pin,
  }) {
    switch (pinGuard.check(pin)) {
      case PinCheckResult.notRequired:
      case PinCheckResult.ok:
        break;
      case PinCheckResult.invalid:
        return (response: null, status: 401);
      case PinCheckResult.tooManyAttempts:
        return (response: null, status: 429);
    }
    if (!isHosting || _sessionId == null) {
      return (response: null, status: 500);
    }

    _connectionCount++;
    _connections.add(_connectionCount);

    return (
      response: PrepareDownloadResponse(
        info: selfInfo,
        sessionId: _sessionId!,
        files: {for (final e in _files.entries) e.key: e.value.dto},
      ),
      status: 200,
    );
  }

  /// Resolves a `download` request to the file's byte stream, or null if the
  /// session/file is unknown (the route maps null to 404/403).
  DownloadableFile? resolveDownload({
    required String? sessionId,
    required String? fileId,
  }) {
    if (sessionId == null || sessionId != _sessionId || fileId == null) {
      return null;
    }
    return _files[fileId];
  }

  String _randomId(int bytes) {
    const chars = '0123456789abcdef';
    final sb = StringBuffer();
    for (var i = 0; i < bytes * 2; i++) {
      sb.write(chars[_random.nextInt(16)]);
    }
    return sb.toString();
  }

  Future<void> dispose() async => _connections.close();
}
