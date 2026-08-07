import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screen 27/28 — transfer history (empty state for now; persistence lands with
/// the Hive-backed history store).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: l.historyTitle, onBack: () => context.pop()),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 40, color: p.muted),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l.historyEmpty,
                        style: AppText.heading.copyWith(color: p.ink)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l.historyEmptyHint,
                        style: AppText.body.copyWith(color: p.muted),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
