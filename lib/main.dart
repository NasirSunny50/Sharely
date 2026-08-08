import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharely/app.dart';
import 'package:sharely/features/favorites/favourites_store.dart';
import 'package:sharely/features/history/history_store.dart';
import 'package:sharely/features/network/network_controller.dart';
import 'package:sharely/features/settings/settings_controller.dart';
import 'package:sharely/platform/desktop_tray.dart';
import 'package:sharely/platform/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Local persistence for transfer history + favourite devices.
  await Hive.initFlutter();
  final historyStore = await HistoryStore.open();
  final favouritesStore = await FavouritesStore.open();

  // Local notifications + desktop tray (best-effort; no-op where unavailable).
  unawaited(NotificationService.instance.init());
  if (DesktopTray.supported) {
    unawaited(DesktopTray.instance.init());
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      historyStoreProvider.overrideWithValue(historyStore),
      favouritesStoreProvider.overrideWithValue(favouritesStore),
    ],
  );

  // Best-effort startup of the live protocol services (cert, server, discovery).
  // Failures degrade gracefully to offline/manual states.
  unawaited(container.read(networkControllerProvider.notifier).init());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SharelyApp(),
    ),
  );
}
