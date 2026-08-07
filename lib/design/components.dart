import 'package:flutter/material.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/tokens.dart';

/// A base scaffold painted with the app surface colour.
class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.body, this.bottomBar, super.key});
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surface,
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// The primary, 3D "pressable" rust button (the concept's signature CTA).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 58,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: widget.height,
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: enabled ? p.primary : p.primary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: _down
              ? null
              : [
                  BoxShadow(
                    color: p.primaryDark,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: p.onPrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              widget.label,
              style: AppText.bodyLarge.copyWith(
                color: p.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A flat, outlined secondary button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.height = 52,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: p.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          foregroundColor: p.inkSecondary,
        ),
        child: Text(
          label,
          style: AppText.bodyLarge.copyWith(color: p.inkSecondary),
        ),
      ),
    );
  }
}

/// A flat white card with a hairline border and (optionally) a subtle shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.elevated = false,
    this.onTap,
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: p.border),
        boxShadow: elevated
            ? AppElevation.card(dark: p.isDark)
            : AppElevation.none,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: card,
    );
  }
}

/// A small monospace status pill with a pulsing dot (the concept's "Ready").
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, this.onTap, super.key});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: p.successBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: p.successBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingDot(color: p.success),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: AppText.label.copyWith(color: p.successText)),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.pulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: reduce
          ? const AlwaysStoppedAnimation(1)
          : Tween<double>(begin: 1, end: 0.35).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// A back button + title header used across secondary screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({required this.title, this.onBack, this.trailing, super.key});
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.screenH, 0),
      child: Row(
        children: [
          if (onBack != null)
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: p.border),
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    size: 16, color: p.ink),
              ),
            ),
          if (onBack != null) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title,
                style: AppText.title.copyWith(color: p.ink),
                overflow: TextOverflow.ellipsis),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A thin progress bar (aggregate or per-file).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.fraction,
    this.height = 8,
    this.color,
    super.key,
  });
  final double fraction;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: fraction.clamp(0, 1),
        minHeight: height,
        backgroundColor: p.surfaceAlt,
        valueColor: AlwaysStoppedAnimation(color ?? p.primary),
      ),
    );
  }
}

/// A monospace data label (sizes, speed, IPs). Tabular figures built in.
class DataText extends StatelessWidget {
  const DataText(this.text, {this.style, this.color, super.key});
  final String text;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppText.data;
    return Text(text,
        style: base.copyWith(color: color ?? context.palette.muted));
  }
}
