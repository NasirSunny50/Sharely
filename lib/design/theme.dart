import 'package:flutter/material.dart';
import 'package:sharely/design/app_palette.dart';
import 'package:sharely/design/tokens.dart';

/// Builds the light and dark [ThemeData] from tokens. Light-first, with a
/// separately-considered dark theme (§3.5) — the dark palette is authored in
/// [AppColors], not derived by inverting light.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppPalette.light());
  static ThemeData dark() => _build(AppPalette.dark());

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      primary: p.primary,
      onPrimary: p.onPrimary,
      surface: p.surface,
      onSurface: p.ink,
      error: p.primary,
    );

    TextStyle ink(TextStyle s) => s.copyWith(color: p.ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.surface,
      fontFamily: AppFonts.display,
      extensions: [p],
      textTheme: TextTheme(
        displayLarge: ink(AppText.displayLarge),
        displayMedium: ink(AppText.display),
        headlineLarge: ink(AppText.titleLarge),
        titleLarge: ink(AppText.title),
        titleMedium: ink(AppText.heading),
        bodyLarge: ink(AppText.bodyLarge),
        bodyMedium: ink(AppText.body).copyWith(color: p.muted),
        labelLarge: ink(AppText.label),
        bodySmall: AppText.caption.copyWith(color: p.muted),
      ),
      dividerColor: p.border,
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
