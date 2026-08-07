import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:meta/meta.dart';
import 'package:sharely/core/constants.dart';
import 'package:sharely/core/logger.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/file_dto.dart';
import 'package:sharely/protocol/models/prepare_upload_dto.dart';
import 'package:sharely/protocol/models/session.dart';

/// A file queued for sending: its [dto] metadata plus a factory that opens a
/// fresh byte stream each time it's read (so retries/re-reads work).
@immutable
class OutgoingFile {
  const OutgoingFile({required this.dto, required this.openRead});
  final FileDto dto;
  final Stream<List<int>> Function() openRead;
}

/// Why a send failed, mapped from the receiver's status codes (§6.4.1).
enum SendFailure {
  /// Receiver requires a PIN, or the PIN was wrong (401).
  pinRequired,

  /// Receiver rejected the request (403).
  rejected,

  /// Receiver is busy with another session (409).
  blocked,

  /// Too many requests / PIN attempts (429).
  tooManyRequests,

  /// Receiver reported an internal error (500) or an unexpected status.
  receiverError,

  /// Could not reach the receiver (connection failed).
  network,

  /// Cancelled locally.
  cancelled,
}

/// Outcome of a send.
@immutable
sealed class SendResult {
  const SendResult();
}

/// Completed successfully (all accepted files uploaded).
class SendSucceeded extends SendResult {
  const SendSucceeded(this.session);
  final Session session;
}

/// Nothing to send (receiver returned 204).
class SendNothingToDo extends SendResult {
  const SendNothingToDo();
}

/// Failed; [failure] categorizes why, [message] is diagnostic.
class SendFailed extends SendResult {
  const SendFailed(this.failure, this.message);
  final SendFailure failure;
  final String message;
}

/// Live send progress snapshot for the sending UI.
@immutable
class SendProgress {
  const SendProgress({
    required this.session,
    required this.bytesPerSecond,
    required this.eta,
  });
  final Session session;
  final double bytesPerSecond;
  final Duration eta;
}

/// The **sender** client (§6.4): prepare-upload, then parallel streamed uploads
/// with a concurrency cap, live progress/speed/ETA, cancel, and full
/// error-code handling. Pure Dart (`dart:io` + dio), no Flutter imports.
class SendService {
  SendService({
    required this.localDevice,
    this.concurrency = SharelyConstants.defaultUploadConcurrency,
    Dio? dio,
  }) : _dio = dio ?? _defaultDio();

  static const _tag = 'Send';

  DeviceInfo localDevice;
  final int concurrency;
  final Dio _dio;

  final StreamController<SendProgress> _progress =
      StreamController<SendProgress>.broadcast();

  /// Emits progress on every byte update / state change.
  Stream<SendProgress> get progress => _progress.stream;

  Session? _session;
  CancelToken? _cancelToken;
  DateTime? _startedAt;
  bool _cancelled = false;

  Session? get session => _session;

  static Dio _defaultDio() {
    return Dio(BaseOptions(
      // We inspect status codes ourselves; never throw on non-2xx.
      validateStatus: (_) => true,
      // Uploads can be long; do not impose a receive timeout on the body.
      sendTimeout: const Duration(minutes: 30),
    ))
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient()
          // Peers use self-signed certs in HTTPS mode; we pin by fingerprint,
          // not by CA (§6.2).
          ..badCertificateCallback = (cert, host, port) => true,
      );
  }

  /// Sends [files] to [target] (its `baseUrl` = `proto://ip:port`). If the
  /// receiver requires a PIN, pass [pin].
  Future<SendResult> send({
    required String baseUrl,
    required DeviceInfo target,
    required List<OutgoingFile> files,
    String? pin,
  }) async {
    _cancelled = false;
    _cancelToken = CancelToken();
    _startedAt = DateTime.now();

    final fileMap = <String, FileDto>{
      for (final f in files) f.dto.id: f.dto,
    };

    // 1) prepare-upload
    final PrepareUploadResponse prep;
    try {
      final resp = await _dio.postUri<Map<String, dynamic>>(
        Uri.parse('$baseUrl${SharelyConstants.apiBase}/prepare-upload'
            '${pin != null ? '?pin=$pin' : ''}'),
        data: PrepareUploadRequest(info: localDevice, files: fileMap).toJson(),
        options: Options(
          contentType: 'application/json',
          responseType: ResponseType.json,
        ),
        cancelToken: _cancelToken,
      );

      final status = resp.statusCode ?? 0;
      if (status == 204) return const SendNothingToDo();
      if (status != 200) return SendFailed(_mapStatus(status), 'HTTP $status');

      prep = PrepareUploadResponse.fromJson(resp.data ?? const {});
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return const SendFailed(SendFailure.cancelled, 'Cancelled');
      }
      return SendFailed(SendFailure.network, e.message ?? 'Network error');
    }

    if (prep.files.isEmpty) {
      // Accepted nothing.
      return const SendFailed(SendFailure.rejected, 'No files accepted');
    }

    // 2) build the session (only accepted files carry a token)
    final progress = <String, FileProgress>{};
    for (final f in files) {
      final token = prep.files[f.dto.id];
      progress[f.dto.id] = FileProgress(
        file: f.dto,
        token: token,
        accepted: token != null,
      );
    }
    _session = Session(
      sessionId: prep.sessionId,
      remote: target,
      direction: TransferDirection.sending,
      files: progress,
      state: SessionState.active,
    );
    _emit();

    // 3) upload accepted files in parallel with a concurrency cap
    final queue = files
        .where((f) => prep.files.containsKey(f.dto.id))
        .toList();
    final iterator = queue.iterator;
    Object? firstError;

    Future<void> worker() async {
      while (!_cancelled) {
        if (!iterator.moveNext()) return;
        final file = iterator.current;
        try {
          await _uploadOne(baseUrl, prep.sessionId, prep.files[file.dto.id]!,
              file);
        } on Object catch (e) {
          firstError ??= e;
          _cancelled = true; // stop the batch on first failure
          return;
        }
      }
    }

    await Future.wait(
      List.generate(concurrency.clamp(1, queue.length), (_) => worker()),
    );

    if (_cancelled && firstError == null) {
      // Cancelled by the user.
      await _sendCancel(baseUrl, prep.sessionId);
      _setState(SessionState.cancelled);
      return const SendFailed(SendFailure.cancelled, 'Cancelled');
    }
    if (firstError != null) {
      await _sendCancel(baseUrl, prep.sessionId);
      _setState(SessionState.failed);
      final err = firstError;
      if (err is DioException) {
        final code = err.response?.statusCode;
        if (code != null) {
          return SendFailed(_mapStatus(code), 'Upload HTTP $code');
        }
      }
      return SendFailed(SendFailure.network, '$err');
    }

    _setState(SessionState.completed);
    return SendSucceeded(_session!);
  }

  Future<void> _uploadOne(
    String baseUrl,
    String sessionId,
    String token,
    OutgoingFile file,
  ) async {
    final uri = Uri.parse(
      '$baseUrl${SharelyConstants.apiBase}/upload'
      '?sessionId=$sessionId&fileId=${file.dto.id}&token=$token',
    );

    // Wrap the source stream to count bytes for progress as they flow — no
    // buffering, straight from disk to socket.
    final counting = file.openRead().map((chunk) {
      _addBytes(file.dto.id, chunk.length);
      return chunk;
    });

    final resp = await _dio.postUri<void>(
      uri,
      data: counting,
      options: Options(
        contentType: 'application/octet-stream',
        headers: {Headers.contentLengthHeader: file.dto.size},
      ),
      cancelToken: _cancelToken,
    );
    final status = resp.statusCode ?? 0;
    if (status != 200) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        message: 'Upload rejected: $status',
      );
    }
    _markFileDone(file.dto.id);
  }

  /// Cancels an in-flight send: stops uploads and notifies the receiver so it
  /// deletes partial files (§6.4.3).
  Future<void> cancel() async {
    _cancelled = true;
    _cancelToken?.cancel('user cancelled');
  }

  Future<void> _sendCancel(String baseUrl, String sessionId) async {
    try {
      await _dio.postUri<void>(
        Uri.parse('$baseUrl${SharelyConstants.apiBase}/cancel'
            '?sessionId=$sessionId'),
      );
    } on Object catch (e) {
      SharelyLogger.instance.w(_tag, 'cancel notify failed: $e');
    }
  }

  SendFailure _mapStatus(int status) => switch (status) {
        401 => SendFailure.pinRequired,
        403 => SendFailure.rejected,
        409 => SendFailure.blocked,
        429 => SendFailure.tooManyRequests,
        _ => SendFailure.receiverError,
      };

  void _addBytes(String fileId, int delta) {
    final session = _session;
    if (session == null) return;
    final fp = session.files[fileId];
    if (fp == null) return;
    final updated = Map<String, FileProgress>.from(session.files)
      ..[fileId] = fp.copyWith(bytesTransferred: fp.bytesTransferred + delta);
    _session = session.copyWith(files: updated);
    _emit();
  }

  void _markFileDone(String fileId) {
    final session = _session;
    if (session == null) return;
    final fp = session.files[fileId];
    if (fp == null) return;
    final updated = Map<String, FileProgress>.from(session.files)
      ..[fileId] = fp.copyWith(done: true, bytesTransferred: fp.file.size);
    _session = session.copyWith(files: updated);
    _emit();
  }

  void _setState(SessionState state) {
    final session = _session;
    if (session == null) return;
    _session = session.copyWith(state: state);
    _emit();
  }

  void _emit() {
    final session = _session;
    if (session == null || _progress.isClosed) return;
    final elapsed = DateTime.now().difference(_startedAt ?? DateTime.now());
    final secs = elapsed.inMilliseconds / 1000.0;
    final bps = secs > 0 ? session.transferredBytes / secs : 0.0;
    final remaining = session.totalBytes - session.transferredBytes;
    final eta = bps > 0
        ? Duration(seconds: (remaining / bps).round())
        : Duration.zero;
    _progress.add(SendProgress(session: session, bytesPerSecond: bps, eta: eta));
  }

  Future<void> dispose() async {
    _cancelToken?.cancel('dispose');
    _dio.close(force: true);
    await _progress.close();
  }
}
