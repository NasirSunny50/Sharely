import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/core/format.dart';

void main() {
  group('Format.bytes', () {
    test('bytes under 1 KB', () {
      expect(Format.bytes(0), '0 B');
      expect(Format.bytes(1), '1 B');
      expect(Format.bytes(1023), '1023 B');
    });

    test('KB / MB / GB always keep one decimal (matches the design)', () {
      expect(Format.bytes(1024), '1.0 KB');
      expect(Format.bytes(324242), '316.6 KB');
      expect(Format.bytes(1024 * 1024), '1.0 MB');
      expect(Format.bytes(150 * 1024 * 1024), '150.0 MB');
      expect(Format.bytes(1024 * 1024 * 1024), '1.0 GB');
    });
  });

  group('Format.speed', () {
    test('appends /s', () {
      expect(Format.speed(1024), '1.0 KB/s');
      expect(Format.speed(0), '0 B/s');
    });
  });

  group('Format.duration', () {
    test('seconds under a minute', () {
      expect(Format.duration(const Duration(seconds: 14)), '14s');
      expect(Format.duration(Duration.zero), '0s');
    });

    test('minutes + zero-padded seconds', () {
      expect(Format.duration(const Duration(minutes: 2, seconds: 5)), '2m 05s');
      expect(Format.duration(const Duration(minutes: 1)), '1m 00s');
    });
  });
}
