import 'dart:async';
import 'dart:io';

import 'package:sharely/core/logger.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop system-tray integration (§8, §40): quick status, show/hide the
/// window, and quit. Uses the §3 packages `tray_manager` + `window_manager`.
///
/// Only active on desktop; a no-op elsewhere.
class DesktopTray with TrayListener {
  DesktopTray._();
  static final DesktopTray instance = DesktopTray._();

  static const _tag = 'Tray';
  static bool get supported =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Future<void> init() async {
    if (!supported) return;
    try {
      await windowManager.ensureInitialized();
      trayManager.addListener(this);
      await trayManager.setToolTip('Sharely');
      await _rebuildMenu(receiving: true);
    } on Object catch (e) {
      SharelyLogger.instance.w(_tag, 'init failed: $e');
    }
  }

  Future<void> _rebuildMenu({required bool receiving}) async {
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            key: 'status',
            label: receiving ? 'Ready to receive' : 'Not receiving',
            disabled: true,
          ),
          MenuItem.separator(),
          MenuItem(key: 'show', label: 'Open Sharely'),
          MenuItem(
            key: 'toggle',
            label: receiving ? 'Stop receiving' : 'Start receiving',
          ),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit'),
        ],
      ),
    );
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        unawaited(windowManager.show());
      case 'quit':
        unawaited(windowManager.destroy());
    }
  }

  void dispose() => trayManager.removeListener(this);
}
