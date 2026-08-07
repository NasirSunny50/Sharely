import 'package:meta/meta.dart';
import 'package:sharely/protocol/models/device_type.dart';

/// A device as described in LocalSend discovery, `register`, `info`, and the
/// `info` block of prepare-upload/-download payloads (§6.3, §6.4.1, §6.6).
///
/// Pure Dart — no Flutter imports.
@immutable
class DeviceInfo {
  const DeviceInfo({
    required this.alias,
    required this.version,
    required this.fingerprint,
    required this.port,
    required this.protocol,
    this.deviceModel,
    this.deviceType = DeviceType.desktop,
    this.download = false,
  });

  /// Parses the common device-info shape. Extra/unknown keys are ignored.
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      alias: json['alias'] as String? ?? '',
      version: json['version'] as String? ?? '2.0',
      deviceModel: json['deviceModel'] as String?,
      deviceType: DeviceType.fromWire(json['deviceType'] as String?),
      fingerprint: json['fingerprint'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 53317,
      protocol: Protocol.fromWire(json['protocol'] as String?),
      download: json['download'] as bool? ?? false,
    );
  }

  /// Human-readable name shown to peers (e.g. "Nice Orange").
  final String alias;

  /// Protocol version the peer speaks (wire value, e.g. "2.0").
  final String version;

  /// Nullable device model (e.g. "Samsung"). §6.3.1.
  final String? deviceModel;

  /// Device kind; unknown/absent falls back to [DeviceType.desktop].
  final DeviceType deviceType;

  /// HTTPS mode: SHA-256 of the TLS cert. HTTP mode: a random string. §6.2.
  final String fingerprint;

  /// TCP port of the peer's HTTP(S) server.
  final int port;

  /// Whether the peer serves over http or https.
  final Protocol protocol;

  /// Whether the reverse-download API is active. Optional, default false. §6.3.1.
  final bool download;

  /// The canonical device-info object (as used in `register`, `info`, and the
  /// `info` block of transfer payloads). `deviceModel` is emitted as null when
  /// absent (the spec marks it nullable).
  Map<String, dynamic> toJson() => {
        'alias': alias,
        'version': version,
        'deviceModel': deviceModel,
        'deviceType': deviceType.wire,
        'fingerprint': fingerprint,
        'port': port,
        'protocol': protocol.wire,
        'download': download,
      };

  /// A discovery announcement/reply datagram: the device info plus the
  /// `announce` flag (§6.3.1). `announce: true` invites a reply; `false` is a
  /// reply and must not trigger further replies.
  Map<String, dynamic> toAnnouncement({required bool announce}) => {
        ...toJson(),
        'announce': announce,
      };

  DeviceInfo copyWith({
    String? alias,
    String? version,
    Object? deviceModel = _sentinel,
    DeviceType? deviceType,
    String? fingerprint,
    int? port,
    Protocol? protocol,
    bool? download,
  }) {
    return DeviceInfo(
      alias: alias ?? this.alias,
      version: version ?? this.version,
      deviceModel: identical(deviceModel, _sentinel)
          ? this.deviceModel
          : deviceModel as String?,
      deviceType: deviceType ?? this.deviceType,
      fingerprint: fingerprint ?? this.fingerprint,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      download: download ?? this.download,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceInfo &&
      other.alias == alias &&
      other.version == version &&
      other.deviceModel == deviceModel &&
      other.deviceType == deviceType &&
      other.fingerprint == fingerprint &&
      other.port == port &&
      other.protocol == protocol &&
      other.download == download;

  @override
  int get hashCode => Object.hash(
        alias,
        version,
        deviceModel,
        deviceType,
        fingerprint,
        port,
        protocol,
        download,
      );

  @override
  String toString() =>
      'DeviceInfo(alias: $alias, type: ${deviceType.wire}, '
      'fingerprint: $fingerprint, $protocol://:$port, download: $download)';
}

const Object _sentinel = Object();
