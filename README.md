# Sharely

Offline, peer-to-peer file transfer. An AirDrop alternative that works over your
local Wi-Fi — **no internet, no accounts, no cloud, no ads, no telemetry.**
Cross-platform (Android, iOS, Windows, macOS, Linux) from one Flutter codebase.

Sharely is **wire-compatible with LocalSend Protocol v2.1** — it discovers, sends
to, and receives from official LocalSend devices with zero configuration.

## What it does

- Auto-discovers nearby devices (UDP multicast, with a subnet-scan fallback)
- Sends any number of files / folders, no size cap — streamed, never buffered
- Receive with accept / reject / **partial accept** (per-file)
- Live per-file and aggregate progress, speed, ETA, cancel from either side
- HTTPS by default (self-signed cert, fingerprint-pinned); HTTP for browser mode
- **Browser mode**: send to a device with no app — it opens a URL or scans a QR
- Optional 6-digit PIN, favourites (auto-accept), Quick Save
- English + Bangla, light/dark themes

## Develop

```bash
flutter pub get
flutter gen-l10n        # generate localizations from lib/l10n/*.arb
flutter analyze         # must be clean (very_good_analysis)
flutter test            # add --exclude-tags slow to skip crypto/socket tests
flutter run             # on a connected device / desktop
```

Architecture, conventions, and the phase roadmap live in [CLAUDE.md](CLAUDE.md);
design decisions in [DECISIONS.md](DECISIONS.md). The protocol layer
(`lib/protocol/`) is pure Dart with no Flutter imports and is fully unit-testable.

## Windows build note

The Windows desktop build needs the Visual Studio **C++ ATL** component (for
`flutter_local_notifications_windows`). Install once:

```
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" modify --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools" --add Microsoft.VisualStudio.Component.VC.ATL --passive
```

## Troubleshooting — "I can't see the other device"

Sharely needs a network, but never the internet. Most discovery failures are the
network, not the app:

- **Router client isolation / "AP isolation"** blocks all peer traffic. Turn it
  off, or use manual connect (enter the IP / scan the QR).
- **Guest Wi-Fi** almost always isolates clients — use your main network.
- **An active VPN** captures the route and breaks discovery. Turn it off.
- **Firewall**: allow **TCP + UDP port 53317**. On **Windows**, the network must
  be set to **Private** — the Public profile blocks it. On **Linux**,
  `sudo ufw allow 53317`.
- **Mesh Wi-Fi / VLANs** often drop multicast between nodes; use the "Scan
  network" button or manual connect.
- **macOS**: needs the network *server* + *client* entitlements (already set) plus
  the local-network permission prompt on Sonoma+.
- **iOS**: multicast needs Apple's `com.apple.developer.networking.multicast`
  entitlement (approval has lead time); until granted, discovery uses the subnet
  scan + manual IP.

## Interop test matrix (release gate)

| Scenario | Send | Receive |
|---|---|---|
| Sharely ↔ official LocalSend Android | ☐ | ☐ |
| Sharely ↔ official LocalSend Windows | ☐ | ☐ |
| Sharely ↔ official LocalSend iOS | ☐ | ☐ |
| Sharely ↔ Sharely | ✅ (automated) | ✅ (automated) |
| Browser mode (Chrome, Safari, Firefox) | ✅ (automated) | n/a |

## Privacy

No account, no server, no analytics. Nothing you send is ever uploaded — it goes
straight from one device to the other over your LAN. The only log is a local,
user-clearable file.
