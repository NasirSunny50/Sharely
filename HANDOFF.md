# HANDOFF — continue building Sharely

You are picking up an in-progress Flutter app, **Sharely** (offline, LAN-only,
peer-to-peer file transfer, wire-compatible with **LocalSend Protocol v2.1**).
Phases 0–9 of the original build are **done and pushed**; this file lists the
remaining enhancement backlog to finish **serially**, plus the hard environment
rules. Read `CLAUDE.md` and `DECISIONS.md` first — they hold the architecture
rules, conventions, and every decision/gotcha so far.

---

## 0. Hard environment rules (do not violate)

- **NEVER write to / install on the `C:` drive.** It is almost full. All caches,
  temp, and downloads must go to **`H:\Replica of C drive for Claude\`**.
  Persistent user env vars are already set to point there: `GRADLE_USER_HOME`,
  `PUB_CACHE`, `ANDROID_AVD_HOME`, `ANDROID_SDK_HOME`, `TMP`, `TEMP`. They apply
  to newly-launched processes; in a shell that predates them, `export` them per
  command if needed. For your own scratch/temp files use
  `H:\Replica of C drive for Claude\scratch`, never `C:\...\Temp` or `/tmp`.
- **Project root:** `F:\Personal_Passive_Income\Sharely` (on F:, fine to use).
- **Git remote:** `https://github.com/NasirSunny50/Sharely.git`, branch `main`.
  Commit **one green feature per commit** and **push after each**. Commit
  messages end with a `Co-Authored-By: Claude` trailer (see existing history).
  CRLF/LF warnings on commit are harmless (Windows).
- Platform: **Windows 10**, PowerShell + Git Bash. Flutter 3.41.4 stable,
  Dart 3.11. An **Android emulator (API 37, `sdk_gphone16k_x86_64`)** is usually
  running. `adb` is NOT on PATH — use
  `C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe` (add it to
  PATH in each shell).

## 1. Workflow for every task

1. `flutter analyze` must stay **clean** (`very_good_analysis`). No raw hex,
   font size, or `EdgeInsets` number outside `lib/design/tokens.dart` — read
   colours via `context.palette.*`, sizes via `AppSpacing`/`AppRadius`/`AppText`.
2. Every user-facing string goes in **both** `lib/l10n/app_en.arb` and
   `app_bn.arb`, then run `flutter gen-l10n`. No hardcoded strings.
3. `flutter test` must stay green. Fast run: `flutter test --exclude-tags slow`.
4. Add/adjust tests for what you build.
5. When it compiles + analyzes + tests green, **commit and push**.
6. For UI changes, optionally verify on the emulator (install the debug APK via
   adb; the app id is `com.sunny.sharely`, main activity `.MainActivity`).

### Useful commands
```bash
flutter analyze
flutter test                      # add --exclude-tags slow to skip socket/crypto tests
flutter gen-l10n
flutter build apk --debug
# emulator (adb not on PATH):
export PATH="$PATH:/c/Users/User/AppData/Local/Android/Sdk/platform-tools"
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.sunny.sharely -c android.intent.category.LAUNCHER 1
```

## 2. Known gotchas (already learned — don't rediscover)

- **`testWidgets` cannot run real file/socket I/O** (Hive `openBox`, sockets) —
  it deadlocks under the fake-async zone. Keep such work out of widget tests, or
  wrap in `tester.runAsync`. The two boot widget tests deliberately avoid the
  Hive stores because they're read lazily.
- **Pinned plugins** (do not bump without raising the Android toolchain):
  `permission_handler: ^12.0.1`, `receive_sharing_intent: 1.8.0`. Newer releases
  need AGP 9 / Kotlin 2.3 / compileSdk 37.
- `android/build.gradle.kts` forces every subproject's Java + Kotlin target to 17
  (needed by the pinned plugins). Core-library desugaring is on for
  `flutter_local_notifications`.
- **Windows desktop build** needs the VS **C++ ATL** component (one-time elevated
  install) for `flutter_local_notifications_windows`; otherwise it won't link.
  Android is the primary verified target.
- **Emulator NAT:** an emulator's IP is `10.0.2.x`, unreachable from real phones,
  so browser-mode QR / discovery can't be tested emulator↔real-device. Use two
  real devices on the same Wi-Fi (or a real Android + a browser) to test that.
- **Fonts are not bundled** — `tokens.dart` references FamiljenGrotesk /
  MartianMono / AnekBangla by name; the system font is the fallback. Do not add
  a `fonts:` block to pubspec until the actual `.ttf` files exist under
  `assets/fonts/` (a missing font asset fails the build).

## 3. Architecture quick map

- `lib/protocol/` — **pure Dart, no Flutter imports.** Models, discovery,
  server (routes), client (send), security (cert, pin). Returns `Result`, never
  throws to UI. This is fully unit-tested; keep it that way.
- `lib/features/` — UI, one folder per feature. Riverpod spine:
  `settings_controller` (persisted via shared_preferences),
  `network_controller` (owns cert→HTTPS server→discovery→send, browser mode,
  incoming-accept via a `Completer`, records history, wakelock, favourites
  auto-accept). Stores: `history/history_store.dart`,
  `favorites/favourites_store.dart` (Hive, injected in `main()`).
- `lib/design/` — `tokens.dart` (law), `app_palette.dart` (ThemeExtension via
  `context.palette`), `theme.dart` (light+dark), `components.dart`.
- `lib/platform/` — `notifications.dart`, `desktop_tray.dart`, `permissions.dart`,
  `wake.dart`, `background.dart` (foreground-service interface, currently a
  no-op stub).
- Routes are in `lib/app.dart` (go_router, with an onboarding gate).

## 4. Already done in the enhancement pass (do NOT redo)

- Runtime **permissions** (onboarding requests notifications + nearby-devices;
  camera requested at point of use) + a **QR scanner** screen (`/scan`).
- **History** persistence + screen (grouped by day) and **Favourites** +
  auto-accept, with a star toggle on Home device tiles.
- **Wakelock** during send + receive (`WakeGuard`).
- **In-app log viewer** (`/logs`, from Troubleshooting).

## 5. REMAINING BACKLOG — do these serially, one commit each

Do them in this order (most useful first). Each should end analyze-clean,
tests green, committed, and pushed.

1. **Settings editing** (`lib/features/settings/settings_screen.dart`)
   - "This device is called" → rename dialog → `settingsController.setAlias`.
   - "Received files go to" → pick a directory (`file_selector`
     `getDirectoryPath`) → persist `saveDirPath`; also make
     `ReceiveSessionManager.saveDir` follow it.
   - Add a **Security** sub-page (or wire the existing row): PIN on/off (reuse
     `/pin` set flow + a "remove PIN" action clearing `settings.pin`),
     **Quick Save** toggle (`settings.quickSave`).
   - Add an **advanced Network** row: port + multicast address editing, with a
     plain-language warning before the user breaks discovery. Persist to
     settings; these already flow into the controller on next launch.

2. **Send text / clipboard** (new: `lib/features/send/send_text_screen.dart`)
   - A text field (prefill from `Clipboard.getData`), send as an in-memory
     `OutgoingFile` (bytes = utf8 of the text, `fileName` e.g. `message.txt`,
     `fileType: text/plain`). Reachable from the send hub ("Send text" card —
     the hub currently routes the text card to the file picker; point it here).

3. **Open received file** (`open_filex` is already a dependency)
   - Track each received file's final saved path. `ReceiveSessionManager`
     already writes via `ReceivingFile` (which exposes `path`); surface the
     saved paths on the session/state so the UI can open them.
   - Add a **receive-complete** affordance (a completion sheet/screen, or make
     the "transfer complete" notification tappable) with an **Open** button →
     `OpenFilex.open(path)`. Mirror the send-complete screen's language.

4. **Manual connect by IP** (`lib/features/home/manual_connect_screen.dart`)
   - The "Continue" button currently does nothing. Wire it: given the typed IP,
     hit `http(s)://IP:port/api/localsend/v2/info` (accept self-signed) to fetch
     the peer's `DeviceInfo`, build a `DiscoveredDevice`, and
     `context.push('/send', extra: device)`. The QR "scan" path already fills
     the IP field.

5. **Error / edge-state screens** (§ state library)
   - Home already has empty/scanning. Add: **no Wi-Fi** (when
     `networkState.hasWifi == false`) with an "open Wi-Fi settings" action;
     **permission denied**, **disk full**, **transfer failed/rejected/cancelled**
     variants. Strings `stateNoWifi/statePermissionDenied/stateDiskFull` exist;
     add more as needed (en+bn).

6. **Photo / video picker** (§9)
   - A real grid picker with multi-select + running count/size. `file_selector`
     with an image/video `XTypeGroup` is the low-dep option; a true gallery grid
     needs a plugin (e.g. `photo_manager`) — if you add one, FLAG it in
     DECISIONS.md (it's outside build-prompt §3).

7. **Foreground service** (§8, Android) — needs a dep outside §3.
   - Add `flutter_foreground_task` (flag it). Start a foreground service with a
     persistent notification while a transfer is active (wrap via the existing
     `lib/platform/background.dart` `BackgroundKeepAlive` interface, replacing
     `NoopKeepAlive` on Android). Declare the service in the manifest (perms +
     `FOREGROUND_SERVICE_DATA_SYNC` type are already present).

8. **Multicast lock** (§8, Android) — small native channel.
   - In `MainActivity.kt`, acquire `WifiManager.MulticastLock` and expose
     acquire/release over a `MethodChannel`; call it from Dart around discovery
     (`MulticastDiscovery.start`/`stop`). Without it many Android devices receive
     zero multicast datagrams. Keep it behind the platform boundary.

9. **APK sharing** (§ V1.1, Android) — needs a dep.
   - List installed apps + extract the base APK (`device_apps` or a channel).
     The hub already has an "Apps" card. FLAG the dep. Android-only; degrade
     gracefully elsewhere.

10. **Full Bangla audit** (§ i18n) — make sure every ARB key has a real bn
    translation (some newer keys were added; verify none fell back to English),
    and that Bangla doesn't overflow on the transfer/incoming screens.

11. **Accessibility** (§ quality floor) — semantics labels on icon-only buttons,
    a full keyboard path through send/accept on desktop, visible focus, AA
    contrast check. Add `Semantics`/`tooltip` where missing.

12. **Resume of interrupted transfers** — NOTE: the build prompt lists this as
    **out of scope for V1** (§5). Only do it if the user explicitly asks;
    otherwise skip.

## 6. BLOCKED — cannot be done without external input (tell the user)

- **Bundle fonts** — needs the actual `.ttf` files for Familjen Grotesk,
  Martian Mono, Anek Bangla (all on Google Fonts). Ask the user to drop them in
  `assets/fonts/`, then wire `pubspec.yaml` + confirm `tokens.dart` families.
- **App icon** — needs icon art; `flutter_launcher_icons` (not in §3) generates
  from a source image. You may propose a simple generated mark, but the design
  asset is the user's call.
- **Rive Handoff animation** — needs the `.riv` file from the design; a
  reduced-motion-aware `CustomPaint` stand-in is in `send/widgets/handoff.dart`.
- **Signed release builds** — need signing keys/config per platform.
- **iOS build + multicast entitlement** — needs a Mac + Xcode + Apple approval.
- **Windows desktop** — needs the one-time VS C++ ATL install (elevated).

---

When in doubt, match the existing code's patterns and keep the protocol/UI
boundary intact. Work one item at a time, green, committed, pushed.
