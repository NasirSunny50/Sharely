# DECISIONS.md — Sharely

A running log of decisions: what was chosen, what was rejected, and why.

## Phase 0 — Scaffold & conventions

- **Flutter 3.41.4 stable / Dart 3.11.1**, sound null safety. Chosen: matches §3 (latest
  stable 3.x). Rejected: pinning older — no reason to.
- **State management: Riverpod** (`flutter_riverpod` 2.6 + `riverpod_annotation`). Per §3.
  Kept on the 2.x line for now; 3.x is available but is a breaking change with no current need.
- **Routing: go_router** 17.x. Per §3.
- **Result type**: hand-rolled sealed `Result<T, E>` in `lib/core/result.dart` rather than a
  package (dartz/fpdart). Chosen: keeps `protocol/` dependency-light and the API exactly what
  we need (ok/err/map/fold). Rejected: fpdart — heavier, more than we need.
- **Logger**: hand-rolled ring-buffered `SharelyLogger`, pure Dart, no Flutter import, with an
  injectable sink so `protocol/` can log without pulling in the widget/file layers. Chosen to
  honor the "no telemetry, local log only" constraint and the pure-`protocol/` rule. Rejected:
  the `logging`/`logger` packages — would still need our own file+ring-buffer plumbing anyway.
- **Lint: very_good_analysis** 10.x. Removed the default `flutter_lints` include. Disabled
  `sort_pub_dependencies` (fights keeping the `flutter` SDK entry first) and
  `public_member_api_docs` (noise for an app, not a package).
- **Fonts**: will use the approved design's fonts (Familjen Grotesk / Martian Mono / Anek
  Bangla), NOT the build prompt §3.5 names (Bricolage Grotesque / General Sans). Reason: the
  brief states the design is authoritative and "tokens are law / copy comes from the design".
  Flagged to the user; revisit at Phase 6 if they disagree.

- **permission_handler pinned to `^12.0.1`** (resolves to 12.0.3 →
  `permission_handler_android` 13.0.1). The default `^13.0.0` pulls
  `permission_handler_android` 14.0.0, whose `build.gradle.kts` uses the
  `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` DSL and
  `compileSdk 37`, requiring AGP 9 / Kotlin 2.3 — not provided by the current
  stable Flutter (3.41) Gradle toolchain, so the Android build failed at script
  compile time. The 13.0.1 android module uses the older Groovy Gradle
  (`compileSdkVersion 35`) and builds cleanly. Same package (§3-compliant),
  just an older minor. Revisit when Flutter's bundled AGP/Kotlin catches up.

- **receive_sharing_intent pinned to `1.8.0`** (exact). 1.9.0 requires
  `compileSdk 37` / Kotlin 2.4 / the `kotlin {}` DSL — same toolchain-ahead-of-Flutter
  problem as permission_handler. 1.8.0 uses Groovy Gradle, `compileSdk 34`,
  Kotlin 1.9.22, and builds cleanly. Same package, older version. Do NOT loosen to
  `^1.8.0` (that would re-pull 1.9.0). Revisit when Flutter's AGP/Kotlin catches up.

## Phase 6 — UX layer

- **Fonts**: confirmed the design's fonts (Familjen Grotesk / Martian Mono / Anek Bangla) over
  the prompt §3.5 names. Family names referenced in `tokens.dart`; **.ttf files not yet bundled**
  (need to be dropped in `assets/fonts/` + registered in pubspec). Until then the system font is
  the graceful fallback — layout/spacing are correct, exact glyphs are not.
- **Tokens as law**: all colour/type/spacing/radius/elevation/motion live in `lib/design/tokens.dart`
  (the only file with raw hex/sizes). Widgets read semantic colour via a `ThemeExtension`
  (`AppPalette`) exposed as `context.palette.*`. Dark theme authored separately (warm-dark), not inverted.
- **Handoff animation**: shipped as a hand-built `CustomPaint` stand-in (`handoff.dart`) that respects
  `prefers-reduced-motion` (degrades to a static scene). The real Rive asset + state machine is a TODO
  when the design file lands; the API (`HandoffAnimation`/`HandoffComplete`) is stable.
- **Build-all-41 decision**: user chose to build all screens now despite missing exports. Implemented
  the core flow at real fidelity (Home, send hub→review→sending→complete→failed, incoming sheet with
  partial accept, history, favourites, settings). Onboarding, pickers, browser mode, PIN, troubleshooting,
  manual connect, and the desktop two-pane rail remain to be built out — same token/component language.
- **i18n**: `flutter gen-l10n` from `lib/l10n/app_{en,bn}.arb` → `lib/l10n/generated/`. Bangla covers
  the core flow (home/sending/incoming required strings included).
- **App spine**: `NetworkController` (StateNotifier) wires cert→HTTPS server→multicast/subnet discovery→
  send, bridges the incoming-accept decision to the UI via a `Completer`. Best-effort `init()` degrades
  to offline/manual states when permissions/sockets aren't available. Verified: Android APK builds with
  the full UI; Home renders in a widget test.

## Phase 8 — Platform hardening

Native config written (verified by build where possible; on-device is the manual checkpoint):
- **Android** `AndroidManifest.xml`: INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE,
  CHANGE_WIFI_MULTICAST_STATE, POST_NOTIFICATIONS, FOREGROUND_SERVICE(+DATA_SYNC),
  NEARBY_WIFI_DEVICES (neverForLocation). Share-to-Sharely SEND/SEND_MULTIPLE `*/*` intent filters.
- **iOS** `Info.plist`: NSLocalNetworkUsageDescription, NSBonjourServices (`_localsend._tcp`),
  UIFileSharingEnabled, LSSupportsOpeningDocumentsInPlace. `Runner.entitlements` created with
  `com.apple.developer.networking.multicast` — **must be wired as CODE_SIGN_ENTITLEMENTS in Xcode**
  and **needs Apple approval** (lead time); until then iOS uses subnet-scan + manual IP.
- **macOS** entitlements (Debug+Release): network.server + network.client + user-selected files.
- **App code**: `platform/notifications.dart` (flutter_local_notifications, incoming/complete/failed,
  wired into NetworkController), `platform/desktop_tray.dart` (tray_manager + window_manager).

**FLAGGED — needs a decision (deps outside §3):**
- **Android foreground service** for large transfers under Doze: needs native Kotlin `Service` or the
  `flutter_foreground_task` plugin (not in §3). Manifest perms/type are ready; runtime plumbing is
  stubbed behind `platform/background.dart` (`NoopKeepAlive`). Recommend adding `flutter_foreground_task`.
- **Screen-on during transfer** (§8): needs `wakelock_plus` (not in §3). Recommend adding it.
- **Android multicast lock**: `RawDatagramSocket` on many Android devices needs
  `WifiManager.MulticastLock` acquired via a platform channel / plugin to receive datagrams; without
  it Android relies on the subnet-scan fallback. Needs a small native channel — flagged.

### Known environment gap (not a code decision)

- Windows desktop build fails at link time without the VS **C++ ATL** component, required by
  `flutter_local_notifications_windows`. One-time machine install; documented in CLAUDE.md.
  Not downgraded or removed — the plugin is the §3-mandated notifications dependency.
