# Sharely — Design Brief

> Paste this into Claude Design. Work through one section at a time; don't attempt all screens in one pass.

---

## 1. The product

**Sharely** is an offline peer-to-peer file transfer app. Two devices on the same Wi-Fi send files directly to each other — no internet, no account, no cloud, no upload, no size limit. Photos, videos, documents, whole folders, installed apps, clipboard text.

Ships on **Android, iOS, Windows, macOS, Linux**. Built in Flutter from one codebase.

**The one job of the interface:** make an invisible thing — a radio link between two machines a few feet apart — feel physical, immediate, and trustworthy.

**Who uses it:** people who currently use SHAREit, Xender, Bluetooth, or WhatsApp-to-self. Plus developers and IT people moving builds between machines all day. Primary market Bangladesh and South Asia, global English audience alongside.

**The moment that matters:** a file landing should feel like catching something someone threw to you — fast, physical, a little delightful. Not "upload complete."

---

## 2. Visual direction — yours to decide

The palette, typography, and overall aesthetic are your call. Pick a direction with a real point of view and commit to it. Two things to be aware of before you choose:

**The category trap.** Every app in this space looks identical — dark background, neon cyan or lime accent, radar sweep with circular avatars, glassmorphic cards, rocket icon. It reads as cheap and slightly untrustworthy, which is exactly the association Sharely needs to break. Whatever you choose, it should not be mistakable for SHAREit or Xender.

**The depth budget.** The brief asks for real dimensionality, and that's right — but spend it in one place, not evenly across forty screens. Pick a single signature moment (the strongest candidate is the transfer itself: files as physical objects making a real journey from one device to another) and put your full effort there. Keep the picker, history, settings, and troubleshooting screens flat and fast to scan. Premium feel comes from the contrast between one dimensional moment and discipline everywhere else. If a settings row has a drop shadow, the budget is overspent.

Design light and dark themes as two separate considered themes, not one inverted into the other.

---

## 3. Screens — 41 total

Every screen needs **light + dark**, and **mobile (390pt) + desktop (1280pt)**.

### A. Onboarding — 4 screens

1. **Welcome** — states the promise in one line: files go device to device, never through the internet. One primary action to continue.
2. **Name this device** — text input with a generated suggestion (the name other people will see), device-type picker (phone / tablet / laptop / desktop).
3. **Permissions** — explains each permission in the user's terms, not the system's, before the OS dialog fires. Location/nearby-devices, storage, notifications. Each needs a reason a non-technical person accepts.
4. **How it works** — three-beat explanation: both devices on the same Wi-Fi, pick files, tap the person. Skippable.

### B. Home & discovery — 4 screens

5. **Home — devices found** — the main screen. Nearby devices displayed with name, device type, and a sense of link quality. Two primary paths: send something, or sit ready to receive. Access to history, favorites, settings.
6. **Home — scanning, nothing found yet** — active searching state. Must feel like it's working, not stuck.
7. **Home — no Wi-Fi / offline** — Sharely needs a network even though it doesn't need internet. Explain that distinction clearly, with an action to open Wi-Fi settings.
8. **Manual connect** — when auto-discovery fails: enter an IP address, or scan the other device's QR code. Escape hatch for hostile networks.

### C. Selecting what to send — 7 screens

9. **Send hub** — choose what kind of thing to send: photos, videos, files, folders, apps, text. Entry point for the whole send flow.
10. **Photo & video picker** — grid, multi-select, album switching, running count and total size always visible.
11. **File & folder picker** — browsable tree, multi-select, mixed files and folders in one selection.
12. **App picker** — installed apps with icon, name, and APK size. Android only; the screen should degrade gracefully elsewhere.
13. **Send text** — free text or clipboard contents as a message rather than a file.
14. **Selection review** — everything picked, total size and file count, remove individual items, then choose a recipient. The last checkpoint before sending.
15. **Device picker sheet** — appears when the user shares into Sharely from another app's share menu. Skips straight to choosing a recipient.

### D. Transfer — 6 screens

16. **Sending** — per-file rows with individual progress, plus one aggregate indicator. Live speed, ETA, amount remaining, files done vs. total. Cancel available at any moment. *Numbers change several times a second — the layout must not shift when 9.8 MB/s becomes 12.4 MB/s.*
17. **Incoming request** — who's sending, from what device, how many files, total size, with previews. Three outcomes: accept all, reject, or **accept only some files** via per-file checkboxes. This screen interrupts whatever the user was doing, so it must be instantly readable.
18. **Receiving** — mirror of Sending, plus where files are being saved.
19. **Transfer complete** — the payoff moment, and the single best place to spend delight. What arrived, where it went, and immediate actions: open, share onward, send something back.
20. **Transfer failed** — connection lost, disk full, or receiver went away. Says what happened and what to do next. Never blames the user. Offers retry.
21. **Transfer cancelled or rejected** — two variants: the other person declined, or someone cancelled mid-transfer. Calm, not alarming, with a clear way forward.

### E. Browser mode — 3 screens

For sending to someone who doesn't have Sharely installed. Sharely hosts the files and the other person downloads them in a browser.

22. **Browser mode — waiting** — large QR code plus a typed short URL for people who can't scan. Explains what the other person should do. Shows nobody has connected yet.
23. **Browser mode — connected** — someone has opened the link; show download progress from the host side, with the ability to stop sharing.
24. **The web page itself** — what the *receiver* sees in Chrome or Safari. File list with sizes, individual and download-all actions, progress. This is a real designed screen, not an afterthought — for many people it's their first impression of Sharely. Must work on a phone browser and a desktop browser.

### F. Security — 2 screens

25. **Set a PIN** — optional 6-digit code so only people who know it can send to this device. Explains the tradeoff plainly.
26. **Enter PIN** — sender-side entry, with a wrong-PIN state and a lockout state after repeated failures.

### G. Library — 3 screens

27. **History** — past transfers grouped by day, showing direction (sent / received), the other device, file count, size, and outcome. Tapping opens the files; a transfer can be re-sent.
28. **History — empty** — first-run state. An invitation to act, not a shrug.
29. **Favorites** — trusted devices that skip the accept prompt. Add, remove, and per-device auto-accept toggle. Should make the security implication obvious without being scary.

### H. Settings — 6 screens

30. **Settings index** — grouped entry points, current values visible inline where useful.
31. **Appearance** — light / dark / system, language (English / Bangla).
32. **Network** — device alias, port, multicast address, encryption toggle. Advanced territory — should look calm, not intimidating, and warn before the user breaks their own setup.
33. **Save location** — where received files go, with a folder picker and available-space indicator.
34. **Security** — PIN on/off, Quick Save (auto-accept everything) with its risk stated plainly, favorites management entry.
35. **About** — version, open-source licenses, the privacy position stated directly (nothing leaves your network, no accounts, no tracking).

### I. Support — 2 screens

36. **Troubleshooting** — the real reasons transfers fail: router client isolation, guest Wi-Fi, active VPN, firewall blocking, devices on different networks. Diagnostic and actionable, not an FAQ dump.
37. **Connection diagnostic result** — an automated check reporting what's working and what isn't, with a fix for each failure.

### J. Desktop-specific — 3 screens

38. **Desktop home** — not a stretched phone. Persistent left rail, two-pane layout, drag-and-drop as a first-class way to send.
39. **System tray menu** — quick status, toggle receiving on/off, recent transfers, open, quit.
40. **Desktop notifications** — incoming request, transfer complete, transfer failed. Must be actionable from the notification itself.

### K. State library — 1 sheet

41. **Cross-cutting states**, designed once and reused: loading, empty, generic error, permission denied, disk full, filename collision on save, two senders arriving at once, device disappeared mid-transfer.

---

## 4. Constraints

**Must be buildable in Flutter.** Available: perspective transforms, layered shadows, custom painting, fragment shaders, Rive/Lottie animation, sparing backdrop blur. Not available: true 3D scenes with real geometry and lighting, WebGL, video backgrounds, physics engines, heavy per-frame blur. Build depth from layered 2D with perspective and hand-placed shadows — a dimensional-looking object should be a flat asset with gradient, highlight, and shadows, not a rendered model. Deliver any signature animation as a Rive file with a documented state machine.

**Bangla and English.** Every string works in both. Bangla runs 20–30% longer with taller ascenders — never size a control to exactly fit its English label. Show at least home, sending, and incoming request in Bangla.

**Quality floor:** touch targets ≥44pt; primary actions in the bottom third on mobile; AA contrast throughout; visible keyboard focus and a full keyboard path through send and accept on desktop; `prefers-reduced-motion` respected (the signature animation degrades to a cross-fade, not to nothing); no icon-only buttons without a label somewhere in the flow; safe areas, notches, and desktop resize down to 720pt.

---

## 5. Copy

Write the copy as part of the design — all 41 screens, in English and Bangla. It's design material, not filler.

Plain verbs, sentence case, no marketing voice. Name things as people experience them: "Nearby devices," not "discovered peers"; "Sharely can't see other devices," not "multicast discovery failed." An action keeps its name through the whole flow — the button says Send, the progress says Sending, the result says Sent. Errors state what happened and what to do next, without apologizing and without blaming. Empty screens invite action.

---

## 6. Order of work

1. **Screen 5 (Home) first, on its own** — light mode, mobile. Plus the token sheet and type pairing you've chosen. Get this signed off before anything else; if the home screen doesn't land, nothing downstream will.
2. Then the signature transfer moment: screens 16, 19, and the motion spec.
3. Then the rest, in the section order above.

**Deliverables:** all 41 screens (light/dark, mobile/desktop) · token sheet (color, type scale, spacing, radius, elevation, motion) · component sheet (device tile in every state, file row, progress indicator, buttons, sheets, toggles, PIN field, empty state, toast) · motion specs for the signature moment, completion, and scanning · Rive files.

Ask before assuming on anything left open. One focused question beats a beautiful screen built on a wrong guess.
