import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/components.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/features/home/home_screen.dart';
import 'package:sharely/features/home/widgets/device_tile.dart';
import 'package:sharely/features/network/network_controller.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// Chooses the layout: the mobile Home field, or — at desktop widths — a
/// persistent left rail + two-pane layout (a distinct layout, not a stretched
/// phone; §3.5).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) return const _DesktopHome();
    return const HomeScreen();
  }
}

class _DesktopHome extends ConsumerWidget {
  const _DesktopHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final net = ref.watch(networkControllerProvider);

    return AppScaffold(
      body: Row(
        children: [
          // Left rail.
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              border: Border(right: BorderSide(color: p.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: Text('Sharely',
                      style: AppText.title.copyWith(color: p.ink)),
                ),
                const SizedBox(height: AppSpacing.xl),
                _RailItem(
                    icon: Icons.wifi_tethering,
                    label: l.homeNearbyDevices,
                    selected: true,
                    onTap: () {}),
                _RailItem(
                    icon: Icons.history,
                    label: l.tabHistory,
                    onTap: () => context.push('/history')),
                _RailItem(
                    icon: Icons.star_outline,
                    label: l.tabFavourites,
                    onTap: () => context.push('/favourites')),
                _RailItem(
                    icon: Icons.settings_outlined,
                    label: l.tabSettings,
                    onTap: () => context.push('/settings')),
              ],
            ),
          ),
          // Main pane.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Text(l.homeNearbyDevices,
                      style: AppText.titleLarge.copyWith(color: p.ink)),
                ),
                Expanded(
                  child: net.devices.isEmpty
                      ? Center(
                          child: Text(l.homeNothingFound,
                              style: AppText.body.copyWith(color: p.muted)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxl),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 360,
                            mainAxisExtent: 76,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                          ),
                          itemCount: net.devices.length,
                          itemBuilder: (context, i) {
                            final d = net.devices[i];
                            return DeviceTile(
                              device: d,
                              onTap: () => context.push('/send', extra: d),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: SizedBox(
                    width: 220,
                    child: PrimaryButton(
                      label: l.homeSendSomething,
                      icon: Icons.arrow_upward,
                      onPressed: () => context.push('/send'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        color: selected ? p.card : Colors.transparent,
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: selected ? p.primary : p.inkSecondary),
            const SizedBox(width: AppSpacing.md),
            Text(label,
                style: AppText.bodyLarge.copyWith(
                    color: selected ? p.ink : p.inkSecondary)),
          ],
        ),
      ),
    );
  }
}
