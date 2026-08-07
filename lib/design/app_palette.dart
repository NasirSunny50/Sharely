import 'package:flutter/material.dart';
import 'package:sharely/design/tokens.dart';

/// A [ThemeExtension] exposing the full semantic palette resolved for the
/// active brightness. Widgets read colours through `context.palette.*` so no
/// widget outside `tokens.dart` ever names a raw hex value.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.cardSunken,
    required this.fieldTop,
    required this.fieldBottom,
    required this.ink,
    required this.inkSecondary,
    required this.muted,
    required this.mutedLight,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.success,
    required this.successText,
    required this.successBg,
    required this.successBorder,
    required this.favBg,
    required this.favBorder,
    required this.favText,
    required this.scrim,
    required this.isDark,
  });

  factory AppPalette.light() => const AppPalette(
        canvas: AppColors.canvas,
        surface: AppColors.surface,
        surfaceAlt: AppColors.surfaceAlt,
        card: AppColors.card,
        cardSunken: AppColors.cardSunken,
        fieldTop: AppColors.fieldTop,
        fieldBottom: AppColors.fieldBottom,
        ink: AppColors.ink,
        inkSecondary: AppColors.inkSecondary,
        muted: AppColors.muted,
        mutedLight: AppColors.mutedLight,
        border: AppColors.border,
        borderStrong: AppColors.borderStrong,
        primary: AppColors.primary,
        primaryDark: AppColors.primaryDark,
        onPrimary: AppColors.onPrimary,
        success: AppColors.success,
        successText: AppColors.successText,
        successBg: AppColors.successBg,
        successBorder: AppColors.successBorder,
        favBg: AppColors.favBg,
        favBorder: AppColors.favBorder,
        favText: AppColors.favText,
        scrim: AppColors.scrim,
        isDark: false,
      );

  factory AppPalette.dark() => const AppPalette(
        canvas: AppColors.dCanvas,
        surface: AppColors.dSurface,
        surfaceAlt: AppColors.dSurfaceAlt,
        card: AppColors.dCard,
        cardSunken: AppColors.dCardSunken,
        fieldTop: AppColors.dFieldTop,
        fieldBottom: AppColors.dFieldBottom,
        ink: AppColors.dInk,
        inkSecondary: AppColors.dInkSecondary,
        muted: AppColors.dMuted,
        mutedLight: AppColors.dMutedLight,
        border: AppColors.dBorder,
        borderStrong: AppColors.dBorderStrong,
        primary: AppColors.dPrimary,
        primaryDark: AppColors.dPrimaryDark,
        onPrimary: AppColors.dOnPrimary,
        success: AppColors.dSuccess,
        successText: AppColors.dSuccessText,
        successBg: AppColors.dSuccessBg,
        successBorder: AppColors.dSuccessBorder,
        favBg: AppColors.dFavBg,
        favBorder: AppColors.dFavBorder,
        favText: AppColors.dFavText,
        scrim: AppColors.scrim,
        isDark: true,
      );

  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color cardSunken;
  final Color fieldTop;
  final Color fieldBottom;
  final Color ink;
  final Color inkSecondary;
  final Color muted;
  final Color mutedLight;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color success;
  final Color successText;
  final Color successBg;
  final Color successBorder;
  final Color favBg;
  final Color favBorder;
  final Color favText;
  final Color scrim;
  final bool isDark;

  @override
  AppPalette copyWith({bool? isDark}) => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

/// Convenient access: `context.palette.primary`.
extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light();
}
