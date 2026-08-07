import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/theme.dart';
import 'package:sharely/features/favorites/favourites_screen.dart';
import 'package:sharely/features/history/history_screen.dart';
import 'package:sharely/features/home/home_shell.dart';
import 'package:sharely/features/home/manual_connect_screen.dart';
import 'package:sharely/features/onboarding/onboarding_screen.dart';
import 'package:sharely/features/receive/browser_mode_screen.dart';
import 'package:sharely/features/receive/incoming_overlay.dart';
import 'package:sharely/features/security/pin_screen.dart';
import 'package:sharely/features/send/send_flow.dart';
import 'package:sharely/features/settings/settings_controller.dart';
import 'package:sharely/features/settings/settings_screen.dart';
import 'package:sharely/features/settings/troubleshooting_screen.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';

/// Root application widget: Material 3 light/dark theme from tokens, en/bn
/// localization, and the go_router route table (with an onboarding gate).
class SharelyApp extends ConsumerWidget {
  const SharelyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final onboarded = ref.read(settingsProvider).onboarded;
        final atOnboarding = state.matchedLocation == '/onboarding';
        if (!onboarded && !atOnboarding) return '/onboarding';
        if (onboarded && atOnboarding) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeShell()),
        GoRoute(
            path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
        GoRoute(
          path: '/send',
          builder: (c, s) => SendFlow(target: s.extra as DiscoveredDevice?),
        ),
        GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
        GoRoute(
            path: '/favourites', builder: (c, s) => const FavouritesScreen()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        GoRoute(
            path: '/settings/troubleshooting',
            builder: (c, s) => const TroubleshootingScreen()),
        GoRoute(
            path: '/manual', builder: (c, s) => const ManualConnectScreen()),
        GoRoute(path: '/browser', builder: (c, s) => const BrowserModeScreen()),
        GoRoute(path: '/pin', builder: (c, s) => const PinScreen()),
      ],
    );

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) =>
          IncomingOverlay(child: child ?? const SizedBox()),
    );
  }
}
