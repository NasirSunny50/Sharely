import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/models/device_info.dart';
import 'package:sharely/protocol/models/device_type.dart';
import 'package:sharely/protocol/models/file_dto.dart';
import 'package:sharely/protocol/models/session.dart';

const _remote = DeviceInfo(
  alias: 'Peer',
  version: '2.0',
  fingerprint: 'f',
  port: 53317,
  protocol: Protocol.https,
  deviceType: DeviceType.mobile,
);

FileDto _file(String id, int size) =>
    FileDto(id: id, fileName: '$id.bin', size: size, fileType: 'application/octet-stream');

void main() {
  group('FileProgress.fraction', () {
    test('is bytes/size, clamped to [0,1]', () {
      final p = FileProgress(file: _file('a', 100), bytesTransferred: 25);
      expect(p.fraction, 0.25);
      expect(
        FileProgress(file: _file('a', 100), bytesTransferred: 200).fraction,
        1.0,
      );
    });

    test('a 0-byte file is 0 until done, then 1', () {
      final pending = FileProgress(file: _file('z', 0));
      expect(pending.fraction, 0.0);
      expect(pending.copyWith(done: true).fraction, 1.0);
    });
  });

  group('Session aggregates', () {
    test('sums bytes over accepted files only', () {
      final session = Session(
        sessionId: 's',
        remote: _remote,
        direction: TransferDirection.sending,
        files: {
          'a': FileProgress(file: _file('a', 100), bytesTransferred: 50),
          'b': FileProgress(file: _file('b', 100), bytesTransferred: 100),
          'c': FileProgress(
            file: _file('c', 100),
            accepted: false, // partial-accept skip
            bytesTransferred: 0,
          ),
        },
      );
      expect(session.totalBytes, 200); // c excluded
      expect(session.transferredBytes, 150);
      expect(session.fraction, 0.75);
    });

    test('fraction is 1 when all accepted 0-byte files are done', () {
      final session = Session(
        sessionId: 's',
        remote: _remote,
        direction: TransferDirection.receiving,
        files: {
          'a': FileProgress(file: _file('a', 0), done: true),
        },
      );
      expect(session.totalBytes, 0);
      expect(session.fraction, 1.0);
    });

    test('tokens map only includes files with a token', () {
      final session = Session(
        sessionId: 's',
        remote: _remote,
        direction: TransferDirection.sending,
        files: {
          'a': FileProgress(file: _file('a', 1), token: 't-a'),
          'b': FileProgress(file: _file('b', 1)), // no token
        },
      );
      expect(session.tokens, {'a': 't-a'});
    });

    test('copyWith transitions state without touching files', () {
      final session = Session(
        sessionId: 's',
        remote: _remote,
        direction: TransferDirection.sending,
        files: {'a': FileProgress(file: _file('a', 1))},
      );
      final active = session.copyWith(state: SessionState.active);
      expect(active.state, SessionState.active);
      expect(active.files, session.files);
    });
  });
}
