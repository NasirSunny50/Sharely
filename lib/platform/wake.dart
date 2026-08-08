import 'package:sharely/core/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake during an active transfer (§8: "keep the screen
/// awake and warn the user"). Reference-counted so overlapping send/receive
/// transfers don't release each other's lock. Best-effort — failures are
/// logged, never thrown.
class WakeGuard {
  WakeGuard._();
  static final WakeGuard instance = WakeGuard._();

  static const _tag = 'Wake';
  int _holders = 0;

  Future<void> acquire() async {
    _holders++;
    if (_holders == 1) {
      try {
        await WakelockPlus.enable();
      } on Object catch (e) {
        SharelyLogger.instance.w(_tag, 'enable failed: $e');
      }
    }
  }

  Future<void> release() async {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0) {
      try {
        await WakelockPlus.disable();
      } on Object catch (e) {
        SharelyLogger.instance.w(_tag, 'disable failed: $e');
      }
    }
  }
}
