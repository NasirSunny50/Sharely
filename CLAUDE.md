# CLAUDE.md — Sharely engineering guide

Context for any future session working on this repo. Read this before writing code.

## What Sharely is

Cross-platform, **offline, peer-to-peer** file transfer app in Flutter. An AirDrop
alternative over the local network: **no internet, no accounts, no cloud, no ads,
no telemetry.** Targets **Android, iOS, Windows, macOS, Linux** from one codebase.

**Wire-compatible with LocalSend Protocol v2.1.** A Sharely device must discover,
send to, and receive from an official LocalSend device with zero configuration.
The protocol spec is authoritative — see `Sharely-ClaudeCode-Build-Prompt.md` §6.
Do not invent protocol behavior; if an idea conflicts with the spec, the spec wins.

Package / bundle ID: `com.sunny.sharely`.

## Non-negotiable constraints

1. Zero recurring cost — no backend, no cloud, no paid API.
2. Offline-first — must fully work with Wi-Fi on and internet off; no call leaves the LAN.
3. No telemetry / analytics / crash-reporting SDK. Local, user-clearable log file only.
4. Protocol fidelity over cleverness.
5. Single shared Dart core; platform differences live behind interfaces in `lib/platform/`.
6. Large files must stream — never load a whole file into memory (8 GB file, 3 GB RAM phone).
7. One clean, tested, green commit per phase. Never start phase N+1 with phase N red.

## Architecture rules

- `lib/protocol/` is **pure Dart** — no `package:flutter` imports. It is unit-testable
  without a Flutter binding. Enforced by convention; check imports before committing.
- `lib/protocol/` never imports `lib/features/`. `lib/features/` never constructs raw sockets.
- Every network/protocol operation returns `Result<T, E>` (see `lib/core/result.dart`) —
  **never throw across layers** to the UI.
- All timeouts, ports, and addresses come from settings, never hardcoded at call sites.
  Defaults live in `lib/core/constants.dart`.
- Feature-first structure with a hard protocol/UI boundary.

## Design rules (Phase 6)

- The UI is already designed — see `Sharely-Design-Brief.md` and the Home screen concept
  in `Home screen design concept/`. Implement it; do not invent UI.
- `lib/design/tokens.dart` is built first, from the design's token sheet. After that,
  **no widget may contain a raw hex color, raw font size, or raw EdgeInsets number** —
  everything references a token.
- Fonts (per the approved design): **Familjen Grotesk** (display/body), **Martian Mono**
  (data — sizes, speed, ETA, IPs, PIN, fingerprints), **Anek Bangla** (Bangla). Bundle them;
  do not fetch at runtime. Use `FontFeature.tabularFigures()` on every changing number.
  NOTE: the build prompt §3.5 named Bricolage Grotesque / General Sans, but the approved
  design uses the fonts above; the design is authoritative. Flagged with the user.
- Light-first with a separately-designed real dark theme (not an inversion).
- Depth budget: full depth only on the home field and the Handoff moment. One elevation
  step on transfer screens / incoming sheet / completion. Everything else is flat.
- Copy comes from the design verbatim, English + Bangla, in ARB files. Do not paraphrase.
- Desktop is a distinct layout (left rail, two-pane), not a stretched phone.

## Palette (from the Home concept, provisional until the full token sheet lands)

- Canvas `#DCD6C8` · Surface `#F4F1EA` · Card `#FFFFFF` · Ink `#14120F`
- Primary (rust/orange) `#C33C15` · Primary-dark `#8E2A0D` · on-primary `#FFF6F2`
- Muted text `#6B6459` / `#8C8477` · Border `#E4DED1`
- Success green `#3E7B33` / `#2E5C26`

## Folder layout

See `Sharely-ClaudeCode-Build-Prompt.md` §4 for the full tree. Top level under `lib/`:
`core/`, `protocol/` (models, discovery, server/routes, client, security),
`features/` (home, send, receive, history, favorites, settings), `platform/`, `design/`, `l10n/`.

## Protocol defaults (LocalSend v2.1)

- Multicast UDP: port `53317`, group `224.0.0.167` (inside 224.0.0.0/24).
- HTTP(S) TCP: port `53317`. Both user-configurable.
- Fingerprint: HTTPS = SHA-256 of the TLS cert; HTTP = random string. Persist cert+fingerprint.
- API base: `/api/localsend/v2` — routes: register, prepare-upload, upload, cancel,
  prepare-download, download, info.

## Conventions

- Lint: `very_good_analysis` (see `analysis_options.yaml`). `flutter analyze` must be clean.
- Naming: `lowerCamelCase` members, `UpperCamelCase` types, `snake_case.dart` files.
- Tests: `flutter_test` + `mocktail`; integration via `integration_test`. Run `flutter test`
  before every commit.
- Commit format: `feat(protocol): implement prepare-upload route`,
  `fix(discovery): release multicast lock on pause`. One commit per phase.
- Do not add a dependency outside `Sharely-ClaudeCode-Build-Prompt.md` §3 without flagging why.
- Do not silently downgrade a requirement (e.g. buffering instead of streaming) — flag it.
- Update this file when an architectural decision is made; log choices in `DECISIONS.md`.

## Phase roadmap (each = one green commit)

0. Scaffold & conventions — **done**.
1. Protocol models & serialization — **done** (DTOs in `lib/protocol/models/`, 30 tests green).
2. Certificate manager & HTTPS shelf server skeleton (`/info`, `/register`) — **done** (8 tests, incl. TLS fingerprint == announced).
3. Discovery (multicast + subnet fallback) — **done** (registry/TTL/self-filter unit-tested; subnet scan e2e-tested; live-LocalSend interop is the manual checkpoint).
4. Receive path (prepare-upload, streamed upload, cancel, session manager) — **done** (11 e2e tests incl. SHA-256 byte-identity, partial/reject/cancel/409/PIN).
5. Send path (parallel streamed uploads, error handling, PIN, 409) — **done** (7 e2e Sharely→Sharely tests incl. SHA-256, partial, PIN, cancel-no-orphan).
6. UX layer — **done** (screens built to the concept's language; assets are stand-ins).
   Design system: `tokens.dart` (law), `app_palette.dart` (ThemeExtension), `theme.dart`
   (light+dark), `components.dart`. l10n en+bn via gen-l10n. Riverpod spine: `settings_controller`
   (persisted) + `network_controller` (cert→server→discovery→send, incoming-accept bridged via
   Completer). Screens: onboarding (4-step, gates the app), Home (mobile field + desktop two-pane
   `home_shell`), send flow (hub→review→sending→complete→failed) with Handoff stand-in,
   incoming-request sheet (partial accept), history, favourites, settings (+security/troubleshooting),
   manual connect, troubleshooting, PIN set/enter (keypad), browser-mode waiting (QR + URL).
   STAND-INS kept per user: (a) fonts not bundled — families referenced, system fallback until
   `.ttf`s land in assets/fonts/ + pubspec; (b) Handoff is a reduced-motion-aware CustomPaint, not
   the Rive asset. Browser-mode transfer itself is wired in Phase 7.
7. Browser / reverse mode + QR — **done** (download session manager, prepare-download/download/web
   routes on plain HTTP, self-contained styled web page, QR/URL waiting screen with live connection
   count; 5 e2e tests incl. byte-identity + headers + PIN). Browser port = main port + 1.
8. Platform hardening — **done (config + app code); 3 native gaps flagged in DECISIONS.md**
   (foreground service, wakelock, multicast lock need deps outside §3). Android manifest perms +
   share intents, iOS Info.plist + multicast entitlement file, macOS entitlements, notifications,
   desktop tray all in place; Android APK builds.
9. Test suite & release prep — **done (automated parts)**: 93 tests green (format, file_writer edge
   cases — collision/traversal/emoji/Bangla/300-char/0-byte — plus all protocol e2e). CI workflow
   (`.github/workflows/ci.yaml`: analyze + test + Android build). README with the router/firewall
   troubleshooting checklist + interop matrix. FLAGGED: app icons need `flutter_launcher_icons`
   (not §3) + icon art; signed/packaged release artifacts per platform are a CI/device task
   (Android debug APK builds green here).

## Android build notes (Phase 0)

- **Pinned plugins** to keep the build on stable Flutter 3.41's Gradle toolchain:
  `permission_handler ^12.0.1` and `receive_sharing_intent 1.8.0` (exact). Their newest
  releases target `compileSdk 37` / Kotlin 2.3–2.4 / the `kotlin{}` DSL, which the bundled
  AGP/Kotlin can't build. Do not bump these without also raising the Android toolchain. See
  DECISIONS.md.
- **`android/app/build.gradle.kts`**: core library desugaring is enabled
  (`isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4`) — required by
  `flutter_local_notifications`.
- **`android/build.gradle.kts`**: a `subprojects` block forces every Android module's Java
  and Kotlin target to 17 (Java via the AGP `BaseExtension.compileOptions`, Kotlin via
  `KotlinCompile.compilerOptions.jvmTarget`) to avoid "Inconsistent JVM Target" failures from
  pinned plugins. Use `compilerOptions` (not `kotlinOptions`, which is a hard error in Kotlin 2.2+).

## Known environment gaps

- **Windows desktop build** needs the Visual Studio **C++ ATL** component
  (`Microsoft.VisualStudio.Component.VC.ATL`) for `flutter_local_notifications_windows`.
  Install it via the Visual Studio Installer once per machine. Our code is fine without it;
  only the Windows build link step needs it.
