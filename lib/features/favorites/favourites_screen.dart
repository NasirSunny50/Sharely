import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/favorites/favourites_store.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Screen 29 — favourites (trusted devices that skip the accept prompt),
/// backed by Hive.
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final store = ref.watch(favouritesStoreProvider);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: l.favouritesTitle, onBack: () => context.pop()),
          Expanded(
            child: AnimatedBuilder(
              animation: store.changes,
              builder: (context, _) {
                final favourites = store.all();
                if (favourites.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline, size: 40, color: p.muted),
                        const SizedBox(height: AppSpacing.lg),
                        Text(l.favouritesEmpty,
                            style: AppText.heading.copyWith(color: p.ink)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  itemCount: favourites.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final d = favourites[i];
                    return AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: p.favBg,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(Icons.star, color: p.favText, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.alias,
                                    style: AppText.bodyLarge
                                        .copyWith(color: p.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(l.favouritesAutoAccept,
                                    style: AppText.caption
                                        .copyWith(color: p.muted)),
                              ],
                            ),
                          ),
                          Switch(
                            value: d.autoAccept,
                            activeThumbColor: p.onPrimary,
                            activeTrackColor: p.primary,
                            onChanged: (v) => store.setAutoAccept(
                                d.fingerprint,
                                value: v),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 18, color: p.muted),
                            onPressed: () => store.remove(d.fingerprint),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
