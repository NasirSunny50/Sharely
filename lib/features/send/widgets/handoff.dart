import 'package:flutter/material.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/tokens.dart';

/// The signature "Handoff" — files as physical cards flying from YOU to the
/// receiver. The design ships this as a Rive file with a documented state
/// machine; until the Rive asset is in the repo this is a faithful hand-built
/// stand-in driven by an animation controller. **Respects reduced-motion**: it
/// degrades to a static cross-faded scene, not a spinner.
class HandoffAnimation extends StatefulWidget {
  const HandoffAnimation({super.key});

  @override
  State<HandoffAnimation> createState() => _HandoffAnimationState();
}

class _HandoffAnimationState extends State<HandoffAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.handoff,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _HandoffPainter(
                t: reduce ? 0.5 : _c.value,
                reduce: reduce,
                palette: context.palette,
              ),
            );
          },
        );
      },
    );
  }
}

class _HandoffPainter extends CustomPainter {
  _HandoffPainter({required this.t, required this.reduce, required this.palette});
  final double t;
  final bool reduce;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final youRect = Rect.fromLTWH(20, size.height - 120, 76, 96);
    final themRect = Rect.fromLTWH(size.width - 170, 14, 150, 98);

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(youRect, const Radius.circular(14)),
        Paint()..color = palette.ink,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(themRect, const Radius.circular(12)),
        Paint()..color = palette.card,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(themRect, const Radius.circular(12)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = palette.borderStrong,
      );

    // Flying cards.
    final start = youRect.center;
    final end = themRect.center;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      final pos = Offset.lerp(start, end, Curves.easeInOut.transform(phase))!;
      double opacity;
      if (reduce) {
        opacity = 1;
      } else if (phase < 0.1) {
        opacity = phase * 10;
      } else if (phase > 0.88) {
        opacity = (1 - phase) * 8.3;
      } else {
        opacity = 1;
      }
      opacity = opacity.clamp(0.0, 1.0);
      final scale = 0.7 + 0.34 * (1 - (phase - 0.5).abs() * 2);
      final w = 96 * scale;
      final h = 68 * scale;
      final rect = Rect.fromCenter(center: pos, width: w, height: h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()..color = palette.primary.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_HandoffPainter old) => old.t != t;
}

/// The completion moment: three cards landed with a "SENT" stamp.
class HandoffComplete extends StatelessWidget {
  const HandoffComplete({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.rotate(
              angle: (i - 1) * 0.08,
              child: Container(
                width: 150,
                height: 104,
                margin: EdgeInsets.only(top: i * 6, left: i * 8),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: p.borderStrong),
                  boxShadow: AppElevation.card(dark: p.isDark),
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            right: 40,
            child: Transform.rotate(
              angle: -0.16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: p.primary, width: 2.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text('SENT',
                    style: AppText.badge.copyWith(
                        color: p.primary, fontSize: 13, letterSpacing: 2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
