import 'package:flutter/material.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/tokens.dart';
import 'package:sharely/l10n/generated/app_localizations.dart';

/// The signature "discovery field" — a warm gradient card with two breathing
/// rings behind a "YOU" chip, stating who can see you and the privacy promise.
class DiscoveryField extends StatefulWidget {
  const DiscoveryField({
    required this.networkName,
    required this.visibleCount,
    super.key,
  });

  final String networkName;
  final int visibleCount;

  @override
  State<DiscoveryField> createState() => _DiscoveryFieldState();
}

class _DiscoveryFieldState extends State<DiscoveryField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.breathe,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Container(
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.fieldTop, p.fieldBottom],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: p.border),
      ),
      child: Stack(
        children: [
          if (!reduce)
            Positioned(
              left: -30,
              top: -17,
              child: _Ring(controller: _c, size: 130, color: p.favBorder),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.ink,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text('YOU',
                      style: AppText.dataSmall.copyWith(color: p.surface)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.homeVisibleTo(widget.networkName, widget.visibleCount),
                        style: AppText.bodyLarge.copyWith(color: p.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(l.homePrivacyLine,
                          style: AppText.label.copyWith(color: p.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
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

class _Ring extends StatelessWidget {
  const _Ring({required this.controller, required this.size, required this.color});
  final AnimationController controller;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Opacity(
          opacity: 0.55 - 0.4 * t,
          child: Transform.scale(
            scale: 1 + 0.14 * t,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}
