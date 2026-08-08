import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:sharely/core/logger.dart';

/// Which Sharely capability a permission unlocks — used to explain *why* in the
/// user's terms, before the OS dialog fires.
enum SharelyPermission { notifications, nearbyDevices, camera }

/// Thin wrapper over `permission_handler` for the permissions Sharely actually
/// needs. Requests are explained in the UI first (onboarding / at point of use)
/// and every call degrades gracefully — a denied permission never crashes the
/// app, it just limits the matching feature.
class PermissionsService {
  const PermissionsService();

  static const _tag = 'Permissions';

  /// Notifications — so "someone is sending you files" can reach the user
  /// (Android 13+ requires a runtime grant; iOS prompts too).
  Future<bool> requestNotifications() => _request(Permission.notification);

  /// Camera — only needed to scan another device's QR code.
  Future<bool> requestCamera() => _request(Permission.camera);

  /// Nearby devices — helps discovery on Android. On Android 13+ this is
  /// `NEARBY_WIFI_DEVICES`; on older versions Wi-Fi info needs location. iOS
  /// has no equivalent runtime permission (multicast is gated by an
  /// entitlement instead), so we report success there.
  Future<bool> requestNearbyDevices() async {
    if (!Platform.isAndroid) return true;
    final nearby = await _request(Permission.nearbyWifiDevices);
    if (nearby) return true;
    // Fall back to location on devices where nearby-wifi isn't available.
    return _request(Permission.locationWhenInUse);
  }

  /// Requests the set shown on the onboarding Permissions step. Returns a map
  /// of what was granted so the UI can reflect it. Camera is intentionally
  /// left for point-of-use (opening the scanner).
  Future<Map<SharelyPermission, bool>> requestOnboarding() async {
    return {
      SharelyPermission.notifications: await requestNotifications(),
      SharelyPermission.nearbyDevices: await requestNearbyDevices(),
    };
  }

  Future<bool> isGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted || status.isLimited;
  }

  /// True once the user has permanently denied — the app should then send them
  /// to system settings rather than re-prompting (the OS won't show the dialog
  /// again).
  Future<bool> isPermanentlyDenied(Permission permission) =>
      permission.isPermanentlyDenied;

  Future<void> openSettings() => openAppSettings();

  Future<bool> _request(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted || status.isLimited;
    } on Object catch (e) {
      // e.g. the permission isn't applicable on this platform/OS version.
      SharelyLogger.instance.w(_tag, 'request ${permission.value} failed: $e');
      return false;
    }
  }
}
