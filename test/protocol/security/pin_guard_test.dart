import 'package:flutter_test/flutter_test.dart';
import 'package:sharely/protocol/security/pin_guard.dart';

void main() {
  test('no PIN configured -> notRequired', () {
    final g = PinGuard();
    expect(g.check(null), PinCheckResult.notRequired);
    expect(g.check('123456'), PinCheckResult.notRequired);
  });

  test('correct PIN -> ok and resets failures', () {
    final g = PinGuard()..pin = '123456';
    expect(g.check('000000'), PinCheckResult.invalid);
    expect(g.recentFailures, 1);
    expect(g.check('123456'), PinCheckResult.ok);
    expect(g.recentFailures, 0); // reset on success
  });

  test('wrong PIN -> invalid', () {
    final g = PinGuard()..pin = '123456';
    expect(g.check('000000'), PinCheckResult.invalid);
    expect(g.check(null), PinCheckResult.invalid);
  });

  test('10 wrong attempts -> 11th is tooManyAttempts (429), not an oracle', () {
    final g = PinGuard(maxAttempts: 10)..pin = '123456';
    for (var i = 0; i < 10; i++) {
      expect(g.check('000000'), PinCheckResult.invalid);
    }
    // Now locked out — even the CORRECT pin is refused, so it can't be used as
    // a brute-force oracle.
    expect(g.check('123456'), PinCheckResult.tooManyAttempts);
    expect(g.check('000000'), PinCheckResult.tooManyAttempts);
  });

  test('lockout clears after the window elapses', () {
    var now = DateTime(2026);
    final g = PinGuard(
      maxAttempts: 3,
      window: const Duration(minutes: 1),
      clock: () => now,
    )..pin = '123456';

    for (var i = 0; i < 3; i++) {
      g.check('000000');
    }
    expect(g.check('123456'), PinCheckResult.tooManyAttempts);

    now = now.add(const Duration(minutes: 2)); // window passed
    expect(g.check('123456'), PinCheckResult.ok);
  });
}
