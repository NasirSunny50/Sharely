import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/favorites/favourites_store.dart';
import 'package:sharely/features/home/widgets/device_tile.dart';
import 'package:sharely/features/home/widgets/discovery_field.dart';
import 'package:sharely/features/network/network_controller.dart';
import 'package:sharely/features/settings/settings_controller.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';

/// Screen 5 — the main Home / discovery field.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final net = ref.watch(networkControllerProvider);
    final settings = ref.watch(settingsProvider);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(alias: settings.alias),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
                AppSpacing.lg, AppSpacing.screenH, 0),
            child: DiscoveryField(
              networkName: net.networkName ?? 'Wi-Fi',
              visibleCount: net.devices.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
                AppSpacing.xl, AppSpacing.screenH, AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.homeNearbyDevices,
                    style: AppText.heading.copyWith(color: p.ink)),
                DataText(
                  net.devices.isEmpty
                      ? l.homeScanning
                      : l.homeScanCount(net.devices.length),
                  style: AppText.dataSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: net.devices.isEmpty
                ? _EmptyDiscovery(scanning: net.ready)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH),
                    itemCount: net.devices.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final d = net.devices[i];
                      final favourites = ref.watch(favouritesStoreProvider);
                      return AnimatedBuilder(
                        animation: favourites.changes,
                        builder: (context, _) {
                          final isFav =
                              favourites.isFavourite(d.info.fingerprint);
                          return DeviceTile(
                            device: d,
                            favourite: isFav,
                            onFavourite: () => favourites.toggle(
                              FavouriteDevice(
                                fingerprint: d.info.fingerprint,
                                alias: d.info.alias,
                              ),
                            ),
                            onTap: () => _pickDevice(context, d),
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0,
                AppSpacing.screenH, AppSpacing.sm),
            child: Column(
              children: [
                PrimaryButton(
                  label: l.homeSendSomething,
                  icon: Icons.arrow_upward,
                  onPressed: () => context.push('/send'),
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: l.homeWaitForSomeone,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const _BottomNav(),
        ],
      ),
    );
  }

  void _pickDevice(BuildContext context, DiscoveredDevice device) {
    unawaited(context.push('/send', extra: device));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.alias});
  final String alias;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.ink,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [BoxShadow(color: p.primary, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.swap_horiz, color: p.surface, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sharely',
                    style: AppText.heading.copyWith(
                        color: p.ink, fontSize: 19, fontWeight: FontWeight.w700)),
                Text(alias,
                    style: AppText.caption.copyWith(color: p.mutedLight),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          StatusPill(label: l.homeReady),
        ],
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  const _EmptyDiscovery({required this.scanning});
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: scanning
                  ? CircularProgressIndicator(
                      strokeWidth: 2, color: p.primary)
                  : Icon(Icons.wifi_find, color: p.muted, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.homeNothingFound,
                style: AppText.heading.copyWith(color: p.ink),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(l.homeNothingFoundHint,
                style: AppText.body.copyWith(color: p.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(
              label: l.manualConnectTitle,
              onPressed: () => context.push('/manual'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      height: 74,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          _NavItem(
              icon: Icons.history,
              label: l.tabHistory,
              onTap: () => context.push('/history')),
          _NavItem(
              icon: Icons.star_outline,
              label: l.tabFavourites,
              onTap: () => context.push('/favourites')),
          _NavItem(
              icon: Icons.settings_outlined,
              label: l.tabSettings,
              onTap: () => context.push('/settings')),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: p.inkSecondary),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: AppText.caption
                    .copyWith(color: p.inkSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
