import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screen 36 — troubleshooting. The real reasons transfers fail, actionable.
class TroubleshootingScreen extends StatelessWidget {
  const TroubleshootingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppScaffold(
      body: ListView(
        children: [
          ScreenHeader(title: l.troubleshootTitle, onBack: () => context.pop()),
          const SizedBox(height: AppSpacing.lg),
          _Item(icon: Icons.router, text: l.troubleshootRouterIsolation),
          _Item(icon: Icons.wifi_password, text: l.troubleshootGuestWifi),
          _Item(icon: Icons.vpn_lock, text: l.troubleshootVpn),
          _Item(icon: Icons.shield_outlined, text: l.troubleshootFirewall),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.md),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: p.primary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(text, style: AppText.body.copyWith(color: p.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
