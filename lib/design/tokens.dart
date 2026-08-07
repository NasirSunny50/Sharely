/// Sharely design tokens — the single source of truth for colour, type,
/// spacing, radius, elevation, and motion (see PROMPT.md §3.5 "Tokens are law").
///
/// **This is the only file in the app allowed to contain a raw hex colour, a
/// raw font size, or a raw spacing number.** Every widget references a token
/// here. Values are derived from the approved Home-screen concept; the dark
/// palette is a separately-considered warm-dark theme, not an inversion.
library;

import 'package:flutter/material.dart';

/// Colour tokens. Two considered palettes: warm-paper light, warm-dark dark.
class AppColors {
  const AppColors._();

  // --- Light (primary) -------------------------------------------------------
  static const canvas = Color(0xFFDCD6C8); // deepest paper (behind cards)
  static const surface = Color(0xFFF4F1EA); // app background
  static const surfaceAlt = Color(0xFFEFEADD); // slightly deeper panel
  static const card = Color(0xFFFFFFFF); // raised cards / rows
  static const cardSunken = Color(0xFFEDE8DC); // wells, icon chips
  static const fieldTop = Color(0xFFFFFFFF); // discovery field gradient top
  static const fieldBottom = Color(0xFFF7F4EC); // discovery field gradient bot

  static const ink = Color(0xFF14120F); // primary text / near-black
  static const inkSecondary = Color(0xFF3A342B); // secondary text
  static const muted = Color(0xFF6B6459); // tertiary text
  static const mutedLight = Color(0xFF8C8477); // quaternary text
  static const border = Color(0xFFE4DED1); // hairline borders
  static const borderStrong = Color(0xFFDCD5C7); // stronger borders

  static const primary = Color(0xFFC33C15); // rust / brand
  static const primaryDark = Color(0xFF8E2A0D); // pressed / 3D shadow
  static const onPrimary = Color(0xFFFFF6F2); // text on primary

  static const success = Color(0xFF3E7B33);
  static const successText = Color(0xFF2E5C26);
  static const successBg = Color(0xFFEAF0E7);
  static const successBorder = Color(0xFFCBD9C4);

  static const favBg = Color(0xFFFCEFEA);
  static const favBorder = Color(0xFFEFC9BC);
  static const favText = Color(0xFFC33C15);

  static const danger = Color(0xFFC33C15);
  static const scrim = Color(0xFF2A2620); // incoming-request backdrop

  // --- Dark (considered, not inverted) --------------------------------------
  static const dCanvas = Color(0xFF0E0D0B);
  static const dSurface = Color(0xFF14120F);
  static const dSurfaceAlt = Color(0xFF1C1A16);
  static const dCard = Color(0xFF211E19);
  static const dCardSunken = Color(0xFF262219);
  static const dFieldTop = Color(0xFF211E19);
  static const dFieldBottom = Color(0xFF14120F);

  static const dInk = Color(0xFFF4F1EA);
  static const dInkSecondary = Color(0xFFDED7C8);
  static const dMuted = Color(0xFFA89F8E);
  static const dMutedLight = Color(0xFF8C8477);
  static const dBorder = Color(0xFF322D25);
  static const dBorderStrong = Color(0xFF3A342B);

  static const dPrimary = Color(0xFFDB4A1E); // a touch brighter on dark
  static const dPrimaryDark = Color(0xFF9E3010);
  static const dOnPrimary = Color(0xFFFFF6F2);

  static const dSuccess = Color(0xFF6FB05F);
  static const dSuccessText = Color(0xFF9FD08F);
  static const dSuccessBg = Color(0xFF1E271B);
  static const dSuccessBorder = Color(0xFF3A4A33);

  static const dFavBg = Color(0xFF2A1C16);
  static const dFavBorder = Color(0xFF5A3020);
  static const dFavText = Color(0xFFDB4A1E);
}

/// Font family names. Bundle the .ttf files under `assets/fonts/` and register
/// them in pubspec.yaml; until then the platform falls back gracefully.
class AppFonts {
  const AppFonts._();

  /// Display + body/UI.
  static const display = 'FamiljenGrotesk';

  /// Data — file sizes, speed, ETA, IPs, PIN, fingerprints. Tabular figures.
  static const mono = 'MartianMono';

  /// Bangla script.
  static const bangla = 'AnekBangla';

  /// Applies tabular figures so changing numbers don't shift the layout.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];
}

/// Spacing scale (logical pixels). Prefer these over raw numbers.
class AppSpacing {
  const AppSpacing._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Standard screen horizontal padding on mobile.
  static const double screenH = 24;
}

/// Corner radii.
class AppRadius {
  const AppRadius._();
  static const double xs = 5;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double sheet = 28;
  static const double device = 46; // phone frame
  static const double pill = 999;
}

/// Named elevations. The depth budget is a build constraint (§3.5): reach for
/// [card] almost everywhere; [floating]/[sheet] only on the moments the design
/// spends depth on. Flat surfaces use `const []`.
class AppElevation {
  const AppElevation._();

  static const List<BoxShadow> none = [];

  static List<BoxShadow> card({required bool dark}) => [
        BoxShadow(
          color: (dark ? Colors.black : AppColors.ink).withValues(alpha: 0.06),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> floating({required bool dark}) => [
        BoxShadow(
          color: (dark ? Colors.black : AppColors.ink).withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> sheet({required bool dark}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.6 : 0.4),
          blurRadius: 40,
          offset: const Offset(0, -20),
        ),
      ];
}

/// Motion durations and curves, matching the concept's CSS.
class AppMotion {
  const AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pulse = Duration(milliseconds: 1800);
  static const Duration breathe = Duration(milliseconds: 3200);
  static const Duration handoff = Duration(milliseconds: 2100);

  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve fly = Cubic(0.4, 0.05, 0.3, 1);
}

/// Type scale. Colour is applied by the theme/widgets, not baked in here.
/// `display` and body use [AppFonts.display]; data uses [AppFonts.mono].
class AppText {
  const AppText._();

  static const String _d = AppFonts.display;
  static const String _m = AppFonts.mono;

  static const TextStyle displayLarge = TextStyle(
      fontFamily: _d, fontSize: 40, fontWeight: FontWeight.w700, height: 1, letterSpacing: -1.5);
  static const TextStyle display = TextStyle(
      fontFamily: _d, fontSize: 30, fontWeight: FontWeight.w600, height: 1.05, letterSpacing: -0.6);
  static const TextStyle titleLarge = TextStyle(
      fontFamily: _d, fontSize: 28, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.8);
  static const TextStyle title = TextStyle(
      fontFamily: _d, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.4);
  static const TextStyle heading = TextStyle(
      fontFamily: _d, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static const TextStyle bodyLarge = TextStyle(
      fontFamily: _d, fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle body = TextStyle(
      fontFamily: _d, fontSize: 15, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle label = TextStyle(
      fontFamily: _d, fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle caption = TextStyle(
      fontFamily: _d, fontSize: 12, fontWeight: FontWeight.w400);

  // Data styles (tabular figures so changing numbers don't jitter).
  static const TextStyle dataLarge = TextStyle(
      fontFamily: _m, fontSize: 44, fontWeight: FontWeight.w600, height: 1,
      letterSpacing: -2, fontFeatures: AppFonts.tabular);
  static const TextStyle data = TextStyle(
      fontFamily: _m, fontSize: 13, fontWeight: FontWeight.w500,
      fontFeatures: AppFonts.tabular);
  static const TextStyle dataSmall = TextStyle(
      fontFamily: _m, fontSize: 11, fontWeight: FontWeight.w500,
      fontFeatures: AppFonts.tabular);
  static const TextStyle mono = TextStyle(
      fontFamily: _m, fontSize: 12, fontWeight: FontWeight.w500);
  static const TextStyle badge = TextStyle(
      fontFamily: _m, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2);
}

/// Responsive breakpoint helper — desktop is a distinct layout, not a stretched
/// phone (§3.5). One helper, used consistently.
class AppBreakpoints {
  const AppBreakpoints._();

  /// Below this width we use the mobile layout; at/above, the desktop layout.
  static const double desktop = 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}
