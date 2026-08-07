/// Rate-limited PIN verification (§6.4.1 `401`, §9 "wrong PIN 10× → 429, not a
/// brute-force oracle").
///
/// Pure Dart — no Flutter imports. The clock is injectable for tests.
library;

/// Outcome of a PIN check.
enum PinCheckResult {
  /// No PIN is configured; access is open.
  notRequired,

  /// PIN matched.
  ok,

  /// PIN missing or wrong (map to HTTP 401).
  invalid,

  /// Too many recent failures; caller is temporarily locked out (map to 429).
  tooManyAttempts,
}

/// Guards a 6-digit PIN against brute force. After [maxAttempts] failures
/// within [window], further checks return [PinCheckResult.tooManyAttempts]
/// until the window elapses — so an attacker can't use the endpoint as an
/// oracle. A correct PIN resets the failure counter.
class PinGuard {
  PinGuard({
    this.maxAttempts = 10,
    this.window = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The configured PIN, or null when no PIN is set.
  String? pin;

  final int maxAttempts;
  final Duration window;
  final DateTime Function() _clock;

  final List<DateTime> _failures = [];

  /// Whether a PIN is currently required.
  bool get isEnabled => pin != null && pin!.isNotEmpty;

  /// Checks [candidate] (may be null when the caller supplied none).
  PinCheckResult check(String? candidate) {
    if (!isEnabled) return PinCheckResult.notRequired;

    _pruneOldFailures();
    if (_failures.length >= maxAttempts) {
      return PinCheckResult.tooManyAttempts;
    }

    if (candidate != null && _constantTimeEquals(candidate, pin!)) {
      _failures.clear();
      return PinCheckResult.ok;
    }

    _failures.add(_clock());
    return PinCheckResult.invalid;
  }

  /// Number of failures still counted within the current window.
  int get recentFailures {
    _pruneOldFailures();
    return _failures.length;
  }

  void reset() => _failures.clear();

  void _pruneOldFailures() {
    final cutoff = _clock().subtract(window);
    _failures.removeWhere((t) => t.isBefore(cutoff));
  }

  /// Length-independent constant-time comparison, so timing can't leak how many
  /// leading digits matched.
  static bool _constantTimeEquals(String a, String b) {
    final ca = a.codeUnits;
    final cb = b.codeUnits;
    var diff = ca.length ^ cb.length;
    final n = ca.length < cb.length ? ca.length : cb.length;
    for (var i = 0; i < n; i++) {
      diff |= ca[i] ^ cb[i];
    }
    return diff == 0;
  }
}
