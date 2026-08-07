/// Enums shared across the LocalSend v2.1 protocol payloads.
///
/// Pure Dart — no Flutter imports (see CLAUDE.md architecture rules).
library;

/// The kind of device, as advertised in discovery and `info` payloads.
///
/// Per spec (§6.3.1): one of `mobile | desktop | web | headless | server`,
/// nullable — **unknown values must fall back to [DeviceType.desktop].**
enum DeviceType {
  mobile,
  desktop,
  web,
  headless,
  server;

  /// Parses a wire value, falling back to [DeviceType.desktop] for null or
  /// any unrecognized string.
  static DeviceType fromWire(String? value) {
    if (value == null) return DeviceType.desktop;
    for (final t in DeviceType.values) {
      if (t.name == value) return t;
    }
    return DeviceType.desktop;
  }

  /// The wire representation (the enum name).
  String get wire => name;
}

/// Transport protocol advertised by a device.
enum Protocol {
  http,
  https;

  /// Parses a wire value, defaulting to [Protocol.http] for null/unknown —
  /// HTTP is the safe assumption when a peer omits the field.
  static Protocol fromWire(String? value) {
    if (value == 'https') return Protocol.https;
    return Protocol.http;
  }

  /// The wire representation (the enum name).
  String get wire => name;
}
