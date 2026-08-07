import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/network/network_controller.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screens 22/23 — browser mode "waiting". Shows a QR + typed URL for a
/// receiver with no app. The reverse-download server that serves this URL is
/// wired in Phase 7; this screen renders the address to scan.
class BrowserModeScreen extends ConsumerWidget {
  const BrowserModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final net = ref.watch(networkControllerProvider);
    final url = net.browserUrl ?? 'http://${net.localIp ?? '—'}:53318';
    final connected = net.browserConnections > 0;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: l.browserWaitingTitle, onBack: () => context.pop()),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: p.border),
                boxShadow: AppElevation.floating(dark: p.isDark),
              ),
              child: QrImageView(
                data: url,
                size: 220,
                backgroundColor: p.card,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: p.ink,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: p.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: DataText(url, style: AppText.data, color: p.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
            child: Text(l.browserWaitingBody,
                style: AppText.body.copyWith(color: p.muted),
                textAlign: TextAlign.center),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!connected)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: p.muted),
                  )
                else
                  Icon(Icons.check_circle, size: 16, color: p.success),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  connected
                      ? l.browserConnected(net.browserConnections)
                      : l.browserNobody,
                  style: AppText.label.copyWith(
                      color: connected ? p.successText : p.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
