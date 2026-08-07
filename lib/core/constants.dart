/// Protocol and app-wide constants.
///
/// These are LocalSend Protocol v2.1 defaults (see PROMPT.md §6.1). They are
/// also the *default* values only — actual runtime values come from settings,
/// never hardcoded at call sites (see §4 rules).
library;

class SharelyConstants {
  const SharelyConstants._();

  /// LocalSend protocol version this app speaks.
  static const String protocolVersion = '2.1';

  /// Advertised protocol version string in discovery payloads.
  /// LocalSend devices announce "2.0" on the wire; we stay compatible.
  static const String announcedVersion = '2.0';

  /// Default TCP port for the HTTP(S) server and UDP multicast port.
  static const int defaultPort = 53317;

  /// Default multicast group. Inside 224.0.0.0/24 because some Android
  /// devices reject other groups (§6.1).
  static const String multicastGroup = '224.0.0.167';

  /// API base path for all LocalSend v2 routes.
  static const String apiBase = '/api/localsend/v2';

  /// Bounded concurrency for subnet-scan discovery (§6.3.2).
  static const int subnetScanConcurrency = 50;

  /// Per-host timeout for subnet scan (§6.3.2).
  static const Duration subnetScanTimeout = Duration(milliseconds: 500);

  /// Default parallel upload concurrency for the send path (§6.4.2).
  static const int defaultUploadConcurrency = 4;

  /// How long a discovered device stays in the list without being seen again.
  static const Duration deviceStaleTtl = Duration(seconds: 6);

  /// Application bundle identifier.
  static const String bundleId = 'com.sunny.sharely';
}
