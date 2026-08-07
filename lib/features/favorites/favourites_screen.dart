import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screen 29 — favourites (trusted devices that skip the accept prompt).
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: l.favouritesTitle, onBack: () => context.pop()),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline, size: 40, color: p.muted),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l.favouritesEmpty,
                      style: AppText.heading.copyWith(color: p.ink)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
