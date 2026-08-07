/// Abstraction over keeping the app alive during transfers (§5, §8).
///
/// On Android a large transfer must run under a **foreground service** with a
/// persistent notification or Doze will kill it. Implementing that requires
/// either native Kotlin (a `Service` with `FOREGROUND_SERVICE_DATA_SYNC`) or a
/// plugin such as `flutter_foreground_task` — the latter is NOT in
/// `Sharely-ClaudeCode-Build-Prompt.md` §3, so it is FLAGGED here rather than
/// silently added. The manifest permissions + service type are already declared
/// (see AndroidManifest.xml); this interface is where the runtime plumbing lands
/// once that dependency decision is made.
///
/// On desktop, the tray + window_manager keep the process alive when minimized.
library;

abstract interface class BackgroundKeepAlive {
  /// Begins keeping the app alive for an active transfer (foreground service on
  /// Android; no-op where unnecessary).
  Future<void> begin({required String title, required String body});

  /// Ends the keep-alive.
  Future<void> end();
}

/// Default no-op used on platforms that don't need explicit keep-alive, and as
/// the safe fallback until the Android foreground-service plugin lands.
class NoopKeepAlive implements BackgroundKeepAlive {
  const NoopKeepAlive();

  @override
  Future<void> begin({required String title, required String body}) async {}

  @override
  Future<void> end() async {}
}
