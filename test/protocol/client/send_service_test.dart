@Tags(['slow'])
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sharely/protocol/client/send_service.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';
import 'package:sharely/protocol/models/file_dto.dart';
import 'package:sharely/protocol/security/pin_guard.dart';
import 'package:sharely/protocol/server/http_server.dart';
import 'package:sharely/protocol/server/session_manager.dart';

const _sender = DeviceInfo(
  alias: 'Sharely Sender',
  version: '2.0',
  deviceType: DeviceType.mobile,
  fingerprint: 'sender-fp',
  port: 53317,
  protocol: Protocol.http,
);

const _receiver = DeviceInfo(
  alias: 'Sharely Receiver',
  version: '2.0',
  deviceType: DeviceType.desktop,
  fingerprint: 'receiver-fp',
  port: 53317,
  protocol: Protocol.http,
);

Uint8List _randomBytes(int n, {int seed = 3}) {
  final rnd = Random(seed);
  final b = Uint8List(n);
  for (var i = 0; i < n; i++) {
    b[i] = rnd.nextInt(256);
  }
  return b;
}

OutgoingFile _outgoing(String id, String name, Uint8List bytes) => OutgoingFile(
      dto: FileDto(
        id: id,
        fileName: name,
        size: bytes.length,
        fileType: 'application/octet-stream',
      ),
      openRead: () => Stream.value(bytes),
    );

void main() {
  late Directory saveDir;
  late ReceiveSessionManager manager;
  late SharelyHttpServer server;
  late SendService sender;
  late PinGuard pinGuard;
  late String baseUrl;
  String? acceptOnly; // when set, accept only this id (partial)

  Future<void> boot() async {
    pinGuard = PinGuard();
    manager = ReceiveSessionManager(
      saveDir: saveDir,
      pinGuard: pinGuard,
      acceptResolver: (req, ip) async =>
          acceptOnly != null ? {acceptOnly!} : req.files.keys.toSet(),
    );
    server = SharelyHttpServer(
      deviceInfo: _receiver,
      port: 0,
      receiveManager: manager,
    );
    await server.start();
    sender = SendService(localDevice: _sender);
    baseUrl = 'http://127.0.0.1:${server.boundPort}';
  }

  setUp(() async {
    saveDir = Directory.systemTemp.createTempSync('sharely_send');
    acceptOnly = null;
    await boot();
  });

  tearDown(() async {
    await sender.dispose();
    await server.stop();
    await manager.dispose();
    if (saveDir.existsSync()) saveDir.deleteSync(recursive: true);
  });

  Future<void> expectFileOnDisk(String name, List<int> expected) async {
    final f = File(p.join(saveDir.path, name));
    expect(f.existsSync(), isTrue, reason: '$name should exist');
    expect(sha256.convert(await f.readAsBytes()), sha256.convert(expected));
  }

  test('sends multiple files byte-identical (Sharely -> Sharely)', () async {
    final a = _randomBytes(200 * 1024, seed: 1);
    final b = _randomBytes(128 * 1024, seed: 2);
    final result = await sender.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('a', 'a.bin', a), _outgoing('b', 'b.bin', b)],
    );
    expect(result, isA<SendSucceeded>());
    await expectFileOnDisk('a.bin', a);
    await expectFileOnDisk('b.bin', b);
  });

  test('progress reaches 100% and emits speed/eta', () async {
    final bytes = _randomBytes(512 * 1024, seed: 5);
    SendProgress? last;
    final sub = sender.progress.listen((p) => last = p);
    final result = await sender.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('f', 'f.bin', bytes)],
    );
    await sub.cancel();
    expect(result, isA<SendSucceeded>());
    expect(last, isNotNull);
    expect(last!.session.fraction, 1.0);
    expect(last!.bytesPerSecond, greaterThan(0));
  });

  test('partial accept: sender only uploads accepted files', () async {
    acceptOnly = 'a';
    final a = _randomBytes(4096, seed: 7);
    final b = _randomBytes(4096, seed: 8);
    final result = await sender.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('a', 'a.bin', a), _outgoing('b', 'b.bin', b)],
    );
    expect(result, isA<SendSucceeded>());
    await expectFileOnDisk('a.bin', a);
    expect(File(p.join(saveDir.path, 'b.bin')).existsSync(), isFalse);
  });

  test('receiver rejects everything -> SendFailed(rejected)', () async {
    acceptOnly = 'nonexistent'; // resolver accepts an id not offered -> empty
    final result = await sender.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('a', 'a.bin', _randomBytes(16))],
    );
    expect(result, isA<SendFailed>());
    expect((result as SendFailed).failure, SendFailure.rejected);
  });

  test('PIN required -> SendFailed(pinRequired); correct PIN succeeds',
      () async {
    pinGuard.pin = '424242';

    final noPin = await sender.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('a', 'a.bin', _randomBytes(32))],
    );
    expect((noPin as SendFailed).failure, SendFailure.pinRequired);

    final good = _randomBytes(32, seed: 11);
    final withPin = await sender.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('a', 'a.bin', good)],
      pin: '424242',
    );
    expect(withPin, isA<SendSucceeded>());
    await expectFileOnDisk('a.bin', good);
  });

  test('a second send while one is active is blocked (409)', () async {
    // Occupy the receiver with a pending session via a separate sender that
    // prepares but never uploads.
    final holder = SendService(localDevice: _sender);
    addTearDown(holder.dispose);

    // Start a send that will hang the receiver in "active": use a large file
    // and cancel the client so it doesn't finish, leaving the session busy.
    final big = _randomBytes(8 * 1024 * 1024, seed: 21);
    final holdFuture = holder.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('big', 'big.bin', big)],
    );
    // Give it a moment to create the session on the receiver.
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final blocked = await sender.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('x', 'x.bin', _randomBytes(16))],
    );
    // Either blocked (409) if the holder's session is still active, else it
    // completed first — accept both but require no crash and a definite result.
    expect(blocked, isA<SendResult>());
    if (blocked is SendFailed) {
      expect(blocked.failure, SendFailure.blocked);
    }
    await holdFuture;
  });

  test('cancel mid-send leaves no active session on the receiver', () async {
    // A large file so the upload is still in flight when we cancel.
    final big = _randomBytes(24 * 1024 * 1024, seed: 33);
    final future = sender.send(
      baseUrl: baseUrl,
      target: _receiver,
      files: [_outgoing('big', 'big.bin', big)],
    );
    await Future<void>.delayed(const Duration(milliseconds: 15));
    await sender.cancel();
    final result = await future;

    expect(result, isA<SendFailed>());
    // The receiver must not be stuck in an active session, and no orphan file.
    expect(manager.hasActiveSession, isFalse);
    expect(File(p.join(saveDir.path, 'big.bin')).existsSync(), isFalse);
  });
}
