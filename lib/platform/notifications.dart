import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sharely/core/logger.dart';

/// Local notifications for incoming requests, completion, and failures (§8).
/// No remote push, no telemetry — purely on-device (honors §2.3).
///
/// Notifications are best-effort: on platforms/setups where the plugin isn't
/// available the calls no-op rather than throwing.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _tag = 'Notify';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      const linux =
          LinuxInitializationSettings(defaultActionName: 'Open Sharely');
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
          linux: linux,
        ),
      );
      _ready = true;
    } on Object catch (e) {
      SharelyLogger.instance.w(_tag, 'init failed: $e');
    }
  }

  NotificationDetails get _details {
    const android = AndroidNotificationDetails(
      'transfers',
      'Transfers',
      channelDescription: 'Incoming requests and transfer results',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();
    const linux = LinuxNotificationDetails();
    return const NotificationDetails(
        android: android, iOS: darwin, macOS: darwin, linux: linux);
  }

  Future<void> _show(int id, String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } on Object catch (e) {
      SharelyLogger.instance.w(_tag, 'show failed: $e');
    }
  }

  Future<void> showIncoming(String from, int fileCount) =>
      _show(1, 'Incoming files', '$from wants to send $fileCount files');

  Future<void> showComplete(int fileCount, String where) =>
      _show(2, 'Transfer complete', '$fileCount files saved to $where');

  Future<void> showFailed(String reason) =>
      _show(3, 'Transfer stopped', reason);

  /// Whether this platform uses local notifications at all.
  static bool get supported =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isLinux ||
      Platform.isWindows;
}
