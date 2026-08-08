import 'package:flutter/material.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/protocol/discovery/discovered_device.dart';
import 'package:sharely/protocol/models/device_type.dart';

/// A nearby-device row (the concept's "puck"): icon chip, name (+ favourite
/// badge), meta line, and a link-quality bar cluster.
class DeviceTile extends StatelessWidget {
  const DeviceTile({
    required this.device,
    required this.onTap,
    this.favourite = false,
    this.onFavourite,
    super.key,
  });

  final DiscoveredDevice device;
  final VoidCallback onTap;
  final bool favourite;
  final VoidCallback? onFavourite;

  IconData get _icon => switch (device.info.deviceType) {
        DeviceType.mobile => Icons.smartphone,
        DeviceType.desktop => Icons.desktop_windows_outlined,
        DeviceType.web => Icons.language,
        DeviceType.headless => Icons.dns_outlined,
        DeviceType.server => Icons.dns_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: p.border),
          boxShadow: AppElevation.card(dark: p.isDark),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: p.cardSunken,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: p.border),
              ),
              child: Icon(_icon, size: 22, color: p.inkSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.info.alias,
                          style: AppText.bodyLarge.copyWith(color: p.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (favourite) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _FavouriteBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${device.info.deviceType.name} · ${device.ip}',
                    style: AppText.label.copyWith(color: p.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _LinkBars(color: p.ink, dim: p.borderStrong),
            if (onFavourite != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  favourite ? Icons.star : Icons.star_outline,
                  size: 20,
                  color: favourite ? p.favText : p.mutedLight,
                ),
                onPressed: onFavourite,
              ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: p.favBg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: p.favBorder),
      ),
      child: Text('★', style: AppText.badge.copyWith(color: p.favText)),
    );
  }
}

class _LinkBars extends StatelessWidget {
  const _LinkBars({required this.color, required this.dim});
  final Color color;
  final Color dim;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(6, color),
        const SizedBox(width: 2.5),
        _bar(10, color),
        const SizedBox(width: 2.5),
        _bar(15, dim),
      ],
    );
  }

  Widget _bar(double h, Color c) => Container(
        width: 4,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(1),
        ),
      );
}
