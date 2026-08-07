# Sharely — Claude Code Build Prompt

> Paste this whole file into Claude Code as the opening prompt (or save it as `PROMPT.md` in an empty repo and tell Claude Code: "Read PROMPT.md and start Phase 0").
> App name is final: **Sharely**. Package/bundle ID: `com.sunny.sharely`.
> Ship the approved design from `Sharely-Design-Brief.md` alongside this — see Section 3.5.

---

## 1. Role & Mission

You are the lead engineer building **Sharely**, a cross-platform, offline, peer-to-peer file transfer app in Flutter. It is an AirDrop alternative that works over the local network with **no internet, no accounts, no cloud, no ads, no telemetry**.

Critical requirement: **Sharely must be wire-compatible with LocalSend Protocol v2.1.** A Sharely device must discover, send to, and receive from an official LocalSend device with zero configuration. The full protocol spec is embedded in Section 6 of this document — implement it exactly. Do not invent your own protocol.

Target platforms (all five): **Android, iOS, Windows, macOS, Linux.**

---

## 2. Non-Negotiable Constraints

1. **Zero recurring cost.** No backend server, no cloud service, no paid API. Everything runs on-device.
2. **Offline-first.** The app must fully function with Wi-Fi on and internet off. No call ever leaves the LAN.
3. **No telemetry, no analytics, no crash reporting SDK.** Local log file only, user-viewable, user-clearable.
4. **Protocol fidelity over cleverness.** If your idea conflicts with the v2.1 spec, the spec wins.
5. **Single shared Dart core.** Platform differences live behind interfaces, never in `if (Platform.isX)` scattered through business logic.
6. **Large files must stream.** Never load a file fully into memory on either side. 8 GB file on a 3 GB RAM phone must work.
7. **Commit per phase.** One clean, working, tested commit at the end of every phase in Section 7. Never start Phase N+1 with Phase N red.

---

## 3. Tech Stack (use these; ask before substituting)

| Concern | Choice |
|---|---|
| Framework | Flutter, latest stable 3.x, Dart 3 with sound null safety |
| State management | Riverpod (`flutter_riverpod` + `riverpod_annotation`) |
| Routing | `go_router` |
| HTTP server (receiver) | `shelf` + `shelf_router` + `shelf_static` |
| HTTP client (sender) | `dio` with streamed request bodies |
| TLS cert generation | `basic_utils` (RSA keypair + self-signed X.509) |
| UDP multicast | `dart:io` `RawDatagramSocket` (no package needed) |
| Local IP / subnet | `network_info_plus` |
| Device name/model | `device_info_plus` |
| File picking (mobile) | `file_picker` |
| File picking (desktop) | `file_selector` |
| Paths | `path_provider`, `path` |
| Persistence | `shared_preferences` for settings, `hive` or `sqflite` for transfer history |
| Permissions | `permission_handler` |
| Receive share intent | `receive_sharing_intent` (Android/iOS "Share to Sharely") |
| QR generate / scan | `qr_flutter`, `mobile_scanner` |
| Notifications | `flutter_local_notifications` |
| Desktop window/tray | `window_manager`, `tray_manager`, `launch_at_startup` |
| Open received file | `open_filex` |
| i18n | `flutter_localizations` + ARB files. Ship `en` and `bn` from Phase 6. |
| Lint | `very_good_analysis` |
| Test | `flutter_test`, `mocktail`, `integration_test` |

---

## 3.5 Design Adherence — the UI is already designed

**A complete design exists. You are implementing it, not inventing it.**

The approved design lives in `Sharely-Design-Brief.md` plus the exported screens, token sheet, component sheet, and Rive files from Claude Design. Read all of it before writing a single widget. If those assets aren't in the repo yet, **stop and ask for them** rather than building placeholder UI you'll throw away.

**Rules:**

1. **Tokens are law.** Build a `lib/design/tokens.dart` from the design's token sheet — colors, type scale, spacing, radius, elevation, motion durations and curves — in Phase 6, before any screen. After that, **no widget may contain a raw hex color, a raw font size, or a raw `EdgeInsets` number.** Everything references a token. If you find yourself typing `Color(0xFF...)` outside `tokens.dart`, you've gone wrong.
2. **Fonts:** Bricolage Grotesque (display), General Sans (body/UI), Martian Mono (data — file sizes, speed, ETA, IPs, PIN, fingerprints). Bundle them; don't fetch at runtime. Use `FontFeature.tabularFigures()` on every changing number so the layout doesn't jitter during transfer.
3. **Light-first with a real dark theme.** Both are designed. Do not generate the dark theme by inverting the light one.
4. **The depth budget is a build constraint, not a suggestion.** Full depth only on the home field and the Handoff animation. One elevation step on transfer screens, the incoming-request sheet, and the completion moment. Everything else — picker, history, favorites, settings, troubleshooting, onboarding — is flat. Do not add shadows the design didn't ask for.
5. **The Handoff** ships as a Rive file with a documented state machine. Drive it from real transfer state; do not reimplement it as hand-written Flutter animation, and do not substitute a generic progress spinner because it was faster.
6. **Copy comes from the design.** Every user-facing string is already written, in English and Bangla. Put them in ARB files verbatim. Do not paraphrase, do not "improve" them, do not invent new strings — if a state needs copy the design doesn't cover, ask.
7. **Desktop is a distinct layout**, not a stretched phone: persistent left rail, two-pane. Build a single breakpoint helper and use it consistently.
8. **Respect `prefers-reduced-motion`** — the Handoff degrades to a cross-fade.

**If the design specifies something Flutter can't hit at 60fps on a mid-range Android device, flag it with a concrete alternative. Do not silently downgrade it and do not silently attempt it anyway.**

Screens to implement, in the design's own grouping: onboarding (3), home field and its empty/scanning states, file selection, send text, device picker, sending, incoming request with partial accept, receiving, transfer complete, the three failure states, browser mode with QR, PIN, history, favorites, settings and sub-pages, troubleshooting, desktop tray and notifications — plus every cross-cutting state the design specifies (loading, empty, error, no Wi-Fi, permission denied, disk full, name collision, two senders at once).



Feature-first, with a hard boundary between protocol logic and UI. Protocol code must be pure Dart and unit-testable with **no Flutter imports**.

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, router, theme
├── core/
│   ├── constants.dart                # defaultPort=53317, multicastGroup=224.0.0.167
│   ├── logger.dart                   # local file logger, ring-buffered
│   ├── result.dart                   # Result<T, E> — no throwing across layers
│   └── extensions/
├── protocol/                         # PURE DART. No 'package:flutter' imports.
│   ├── models/
│   │   ├── device_info.dart          # alias, version, deviceModel, deviceType,
│   │   │                             # fingerprint, port, protocol, download
│   │   ├── file_dto.dart             # id, fileName, size, fileType, sha256,
│   │   │                             # preview, metadata
│   │   ├── prepare_upload_dto.dart
│   │   ├── prepare_download_dto.dart
│   │   └── session.dart              # sessionId, tokens, per-file progress, state
│   ├── discovery/
│   │   ├── multicast_discovery.dart  # announce + listen + reply (§6.3.1)
│   │   ├── http_discovery.dart       # subnet scan fallback (§6.3.2)
│   │   └── discovery_service.dart    # merges both sources, dedupes by fingerprint
│   ├── server/
│   │   ├── http_server.dart          # shelf server, HTTP or HTTPS
│   │   ├── routes/
│   │   │   ├── register_route.dart
│   │   │   ├── prepare_upload_route.dart
│   │   │   ├── upload_route.dart
│   │   │   ├── cancel_route.dart
│   │   │   ├── prepare_download_route.dart
│   │   │   ├── download_route.dart
│   │   │   ├── info_route.dart
│   │   │   └── web_route.dart        # browser-mode static page (§6.5)
│   │   └── session_manager.dart      # single active receive session, 409 others
│   ├── client/
│   │   ├── send_service.dart         # prepare-upload → parallel uploads → cancel
│   │   └── receive_service.dart      # reverse/download mode client
│   └── security/
│       ├── certificate_manager.dart  # generate once, persist, SHA-256 fingerprint
│       └── pin_guard.dart            # rate-limited PIN check, 429 on abuse
├── features/
│   ├── home/                         # radar/grid of nearby devices
│   ├── send/                         # file selection → device pick → progress
│   ├── receive/                      # incoming request sheet, accept/partial/reject
│   ├── history/
│   ├── favorites/
│   └── settings/
├── platform/
│   ├── file_access.dart              # abstract; SAF vs desktop paths vs iOS sandbox
│   ├── background.dart               # abstract; foreground service vs desktop tray
│   └── impl/
└── l10n/
```

**Rules:**
- `protocol/` never imports `features/`. `features/` never constructs raw sockets.
- Every network operation returns `Result`, never throws to the UI layer.
- All timeouts, ports, and addresses come from settings, never hardcoded at call sites.

---

## 5. Feature Scope

### V1 (must ship)
- Auto device discovery via multicast, with subnet-scan fallback
- Send any number of files / whole folders, no size cap
- Send plain text and clipboard content as a message
- Receive with accept / reject / **partial accept** (per-file checkboxes)
- Live per-file and aggregate progress, speed, ETA, cancel from either side
- HTTPS by default with self-signed cert; HTTP toggle for browser mode
- **Browser mode**: receiver has no app → sender hosts a page, receiver opens URL or scans QR
- Optional 6-digit PIN protection
- Favorites (trusted devices auto-accept)
- Quick Save mode (auto-accept everything)
- Configurable save directory, alias, port, multicast address
- Transfer history with re-send
- Dark/light/system theme, Material 3, English + Bangla

### V1 explicitly out of scope (say no if asked)
- Cloud relay / internet transfer / WebRTC
- End-to-end account identity, key exchange beyond TLS fingerprint pinning
- Resume of a partially transferred file across app restarts
- Encryption of files at rest

### V1.1 backlog (design for, don't build)
- APK sharing (Android: list installed apps, extract base APK)
- Wi-Fi Direct / hotspot auto-setup fallback
- Folder sync mode
- CLI/headless build for servers

---

## 6. LocalSend Protocol v2.1 — Implementation Spec

Implement this exactly as written. This is the contract.

### 6.1 Defaults
- **Multicast (UDP):** port `53317`, address `224.0.0.167`. Group is inside `224.0.0.0/24` because some Android devices reject other groups.
- **HTTP (TCP):** port `53317`
- Both must be user-configurable in settings.

### 6.2 Fingerprint
- HTTPS mode: fingerprint = **SHA-256 hash of the TLS certificate**.
- HTTP mode: fingerprint = random generated string.
- Used to avoid self-discovery and to remember devices. Persist your own cert + fingerprint across launches, or Favorites will break on every restart.

### 6.3 Discovery

**6.3.1 Multicast UDP (default)**

On app start, send this JSON to the multicast group:

```json
{
  "alias": "Nice Orange",
  "version": "2.0",
  "deviceModel": "Samsung",
  "deviceType": "mobile",
  "fingerprint": "random string",
  "port": 53317,
  "protocol": "https",
  "download": true,
  "announce": true
}
```

`deviceModel` is nullable. `deviceType` is one of `mobile | desktop | web | headless | server`, nullable — unknown values must fall back to `desktop`. `download` is optional, default `false`, and indicates whether the reverse-download API is active.

Other members reply. **Preferred reply path** is an HTTP POST straight back to the announcer's `/api/localsend/v2/register` with their own device info. **Fallback reply path** is a multicast message with the same shape but `"announce": false`.

A response is only triggered when `announce` is `true` — otherwise you get an infinite announce loop. Ignore any datagram whose `fingerprint` equals your own.

**6.3.2 HTTP legacy mode (fallback when multicast fails)**

`POST /api/localsend/v2/register` to every IP on the local subnet.

Request body: alias, version, deviceModel, deviceType, fingerprint (ignored in HTTPS mode), port, protocol, download.

Response body: alias, version, deviceModel, deviceType, fingerprint, download.

Scan with bounded concurrency (max ~50 in flight) and a short per-host timeout (~500 ms), otherwise you will hang the UI and get flagged by routers.

### 6.4 File Transfer (Upload API) — the default path

The **receiver** runs the HTTP server. The **sender** is the HTTP client.

**6.4.1 Preparation (metadata only)**

`POST /api/localsend/v2/prepare-upload` — add `?pin=123456` if a PIN is required.

```json
{
  "info": {
    "alias": "Nice Orange",
    "version": "2.0",
    "deviceModel": "Samsung",
    "deviceType": "mobile",
    "fingerprint": "random string",
    "port": 53317,
    "protocol": "https",
    "download": true
  },
  "files": {
    "some file id": {
      "id": "some file id",
      "fileName": "my image.png",
      "size": 324242,
      "fileType": "image/jpeg",
      "sha256": "*sha256 hash*",
      "preview": "*preview data*",
      "metadata": {
        "modified": "2021-01-01T12:34:56Z",
        "accessed": "2021-01-01T12:34:56Z"
      }
    }
  }
}
```

`size` is in bytes. `sha256`, `preview`, and `metadata` are nullable. The `files` map key must equal the inner `id`.

Response:

```json
{
  "sessionId": "mySessionId",
  "files": { "someFileId": "someFileToken" }
}
```

The receiver decides: accept, **partially accept** (return tokens only for the accepted subset), or reject.

Error codes you must both emit and handle:

| Code | Meaning |
|---|---|
| 204 | Finished — no file transfer needed |
| 400 | Invalid body |
| 401 | PIN required / invalid PIN |
| 403 | Rejected |
| 409 | Blocked by another session |
| 429 | Too many requests |
| 500 | Unknown error by receiver |

**6.4.2 Send file**

`POST /api/localsend/v2/upload?sessionId=...&fileId=...&token=...`

Body is raw binary. No body in the response. **This route may be called in parallel** — implement a configurable concurrency limit (default 3–5) and stream from disk both ways.

Errors: `400` missing parameters, `403` invalid token or IP address, `409` blocked by another session, `500` unknown error.

Validate that the uploading IP matches the IP that created the session.

**6.4.3 Cancel**

`POST /api/localsend/v2/cancel?sessionId=mySessionId`, no response body. Wire this to sender-side cancel, app backgrounding, and socket death. Receiver must delete partial files on cancel.

### 6.5 Reverse Transfer (Download API) — browser mode

Used when the receiver does not have the app. Here the **sender** runs the HTTP server and the receiver opens a URL.

Must use **plain HTTP, not HTTPS**, because browsers reject self-signed certificates.

- **Browser URL:** `http://<sender-ip>:<sender-port>` — serve a minimal, dependency-free HTML page listing the files with download links. Show this URL plus a QR code in the app UI.
- **`POST /api/localsend/v2/prepare-download`** — no request body; optional `?sessionId=` (so a browser refresh reuses the session) and `?pin=`. Response contains `info`, `sessionId`, and the `files` map. Errors: `401`, `403`, `429`, `500`.
- **`GET /api/localsend/v2/download?sessionId=...&fileId=...`** — returns binary data, callable in parallel. Set `Content-Disposition` and `Content-Length` correctly.

### 6.6 Info (debug only)

`GET /api/localsend/v2/info` returns alias, version, deviceModel, deviceType, fingerprint, download. Legacy discovery route, replaced by `/register`. Implement it for debugging and interop, but do not use it for discovery.

---

## 7. Phased Roadmap

Each phase = one commit. Each phase has a hard acceptance test. **Do not proceed if the acceptance test fails.**

### Phase 0 — Scaffold & conventions
Create the Flutter project for all 5 platforms, the folder structure from Section 4, `very_good_analysis` lint, and a `CLAUDE.md` capturing: architecture rules, naming conventions, the "protocol/ has no Flutter imports" rule, the Result-not-throw rule, commit message format, and the phase list.
**Accept:** `flutter analyze` clean, app builds and runs on Android + one desktop target.

### Phase 1 — Protocol models & serialization
All DTOs from Section 6, with `fromJson`/`toJson`, nullable fields correct, unknown `deviceType` falling back to `desktop`.
**Accept:** unit tests round-trip every DTO, including real captured LocalSend JSON payloads with unknown/extra fields present.

### Phase 2 — Certificate manager & HTTP server skeleton
Generate an RSA keypair and self-signed X.509 cert on first run, persist it, compute the SHA-256 fingerprint. Boot a `shelf` server on 53317 over HTTPS with `/info` and `/register` live.
**Accept:** official LocalSend on another device can hit your `/api/localsend/v2/info` and get a valid response; fingerprint is stable across restarts.

### Phase 3 — Discovery
Multicast announce + listen + HTTP-register reply, self-fingerprint filtering, device list with TTL-based staleness eviction. Subnet-scan fallback behind a manual "Scan network" button.
**Accept:** **your app and official LocalSend see each other in the device list, both directions, within 3 seconds.** This is the single most important checkpoint in the project.

### Phase 4 — Receive path
`prepare-upload` with accept/partial/reject UI sheet, session manager (one active session, `409` for others), streamed `upload` handler writing to disk with collision-safe naming, `cancel`, partial-file cleanup, progress state.
**Accept:** official LocalSend sends 1 file, 20 files, and a 2 GB file to your app; all arrive byte-identical (verify SHA-256). Rejecting and cancelling both behave correctly.

### Phase 5 — Send path
File/folder picker, device selection, `prepare-upload`, parallel streamed uploads with a concurrency cap, progress/speed/ETA, cancel, full error-code handling including PIN and 409.
**Accept:** your app sends the same three payloads to official LocalSend, byte-identical. Sender-side cancel mid-transfer leaves no orphan session on the receiver.

### Phase 6 — UX layer (implement the approved design)
**First:** build `lib/design/tokens.dart` and the theme from the design's token sheet, then the component sheet (device puck states, file row, progress ring, buttons, sheet, toggle, PIN field, empty state, toast). Only then assemble screens.
Then: home field with the Handoff Rive animation wired to real transfer state, transfer progress screens, history (Hive/sqflite), favorites with auto-accept, Quick Save, settings (alias, port, multicast address, save dir, HTTPS toggle, PIN, theme), English + Bangla ARB files from the design's copy, share-intent handling, desktop rail/two-pane layout.
**Accept:** screens match the exported designs in light and dark, at mobile and desktop widths; zero raw hex/size/spacing values outside `tokens.dart`; zero hardcoded user-facing strings; Bangla renders without truncation or overflow on the home, transfer, and incoming-request screens; no layout shift while speed/ETA values update.

### Phase 7 — Browser / reverse mode
HTTP server in download mode, static HTML page, `prepare-download`, `download`, QR code + URL display, PIN gate.
**Accept:** a phone with no app installed downloads a multi-file selection from your desktop app via Chrome and via Safari.

### Phase 8 — Platform hardening
Everything in Section 8. Android foreground service, iOS local-network permission, desktop tray + firewall guidance, screen-on during transfer, notifications.
**Accept:** the 2 GB transfer completes with the screen locked on Android, and with the window minimized on Windows and macOS.

### Phase 9 — Test suite & release prep
Section 9's test suite green, CI workflow, app icons, release builds for all 5 targets, README with the router/firewall troubleshooting checklist.
**Accept:** signed/packaged artifact produced for each platform.

---

## 8. Platform Gotchas — read before Phase 8, not after

**Android**
- Manifest: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `POST_NOTIFICATIONS` (13+), `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_DATA_SYNC` (14+ requires a declared type or it crashes at start).
- **Multicast lock is mandatory** — acquire `WifiManager.MulticastLock` or you will silently receive zero datagrams on many devices. Release it when idle to save battery.
- Storage: target SDK 33+ means scoped storage. Use SAF (`file_picker` with `withReadStream`) for reading, and write to app-specific or user-chosen tree URIs. Do not request `MANAGE_EXTERNAL_STORAGE`; Play will reject it.
- Transfers must run under a foreground service with a persistent notification, or Doze kills them.
- Battery optimization exemption prompt for large transfers.

**iOS** — plan for this early, it has lead time
- Multicast on iOS 14+ requires the **`com.apple.developer.networking.multicast` entitlement, which needs an approval request submitted to Apple.** Submit it as soon as you have a bundle ID. Until it's granted, iOS will only work via the subnet-scan fallback and manual IP entry — build those paths first.
- `NSLocalNetworkUsageDescription` and `NSBonjourServices` in Info.plist.
- Background transfers are heavily limited; keep the screen awake and warn the user.
- Sandbox: save to the app's Documents dir, expose via the Files app (`UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`).

**macOS**
- Entitlements: `com.apple.security.network.client`, `com.apple.security.network.server`, plus user-selected file read/write. Missing the server entitlement is the #1 cause of "everyone can see me but nobody can send to me".
- Local network permission prompt on Sonoma+.

**Windows**
- First run triggers a firewall dialog. Detect the "discovered but unreachable" state and show inline guidance: allow TCP+UDP 53317, and note that **Public network profile blocks it** — user must set the network to Private.

**Linux**
- Package as AppImage + Flatpak. Flatpak needs `--share=network`. Document `ufw allow 53317`.

**Networks (all platforms)** — surface these in an in-app troubleshooting page:
- AP isolation / "client isolation" on the router blocks all peer traffic
- Guest Wi-Fi networks block peer traffic
- An active VPN captures the route and breaks discovery
- Mesh systems and VLANs often drop multicast between nodes

---

## 9. QA & Test Strategy

You are building this for a QA engineer. The test suite is a first-class deliverable, not an afterthought.

**Unit** — DTO round-trips (including malformed, extra, and missing-nullable fields), fingerprint computation, session state machine transitions, PIN rate limiter, filename collision resolution.

**Widget** — accept/reject/partial sheet, progress rendering at 0/50/100%, error states.

**Integration** — spin up two in-process protocol instances on different ports and run full send/receive, partial accept, reject, cancel-from-sender, cancel-from-receiver, and 409-concurrent-session scenarios end to end.

**Interop matrix — the one that actually matters.** Every cell must pass before release:

| Scenario | Send | Receive |
|---|---|---|
| Sharely ↔ official LocalSend Android | ☐ | ☐ |
| Sharely ↔ official LocalSend Windows | ☐ | ☐ |
| Sharely ↔ official LocalSend iOS | ☐ | ☐ |
| Sharely ↔ Sharely | ☐ | ☐ |
| Browser mode (Chrome, Safari, Firefox) | ☐ | n/a |

**Edge cases to explicitly test:**
- 0-byte file; file with no extension; 300-character filename; emoji, Bangla, and RTL characters in filename; two files with identical names in one batch
- 5 GB single file; 500-file batch; nested folder tree
- Wi-Fi dropped mid-transfer; app backgrounded mid-transfer; receiver force-killed mid-transfer
- Disk full on receiver; save directory deleted before transfer starts
- Two senders targeting one receiver simultaneously (must get 409)
- Wrong PIN entered 10 times in a row (must get 429, not a brute-force oracle)
- Device changes IP mid-session (DHCP renew)
- Sender and receiver on different subnets

---

## 10. How to Work

- **Ask before assuming.** If a requirement here is ambiguous, ask one focused question rather than guessing and building the wrong thing.
- **Show me the plan for each phase before writing code for it.** A short bullet list of files you'll create/modify is enough.
- **Never commit red.** Run `flutter analyze` and `flutter test` before every commit.
- Commit format: `feat(protocol): implement prepare-upload route` / `fix(discovery): release multicast lock on pause`.
- Update `CLAUDE.md` whenever an architectural decision is made, so later sessions inherit the context.
- Keep a `DECISIONS.md` log: what was chosen, what was rejected, why.
- Do not add a dependency that isn't in Section 3 without telling me what it is and why the alternative is worse.
- Do not silently downgrade a requirement (e.g. "streaming was hard so I buffered it in memory"). Flag it instead.

**Start now with Phase 0.** Confirm the platform toolchains available in this environment first, then scaffold.
