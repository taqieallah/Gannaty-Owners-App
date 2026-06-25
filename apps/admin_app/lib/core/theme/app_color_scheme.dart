import 'package:flutter/material.dart';

/// Dynamic color tokens that change between light and dark mode.
/// Access via: Theme.of(context).extension<AppColorScheme>()!
/// Or via the helper: context.appColors
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textBody;
  final Color textSecondary;
  final Color textHint;
  final Color navyLight;
  final Color navyPale;
  final Color navy;
  final Color gold;
  final Color goldLight;

  const AppColorScheme({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textBody,
    required this.textSecondary,
    required this.textHint,
    required this.navyLight,
    required this.navyPale,
    required this.navy,
    required this.gold,
    required this.goldLight,
  });

  // ── Light Palette — Warm Parchment & Ivory ─────────────────────────────────
  static const light = AppColorScheme(
    bg: Color(0xFFF4ECDA),          // warm parchment beige
    surface: Color(0xFFFFFEF8),     // warm ivory — cards & dialogs
    surfaceAlt: Color(0xFFF5EBDC),  // warm sand — inputs, alt surfaces
    border: Color(0xFFE5D5B0),      // warm tan border
    borderStrong: Color(0xFFCEB98A), // golden tan
    textPrimary: Color(0xFF2C1810), // deep espresso
    textBody: Color(0xFF5A3828),    // warm brown
    textSecondary: Color(0xFF8A6B55), // warm clay
    textHint: Color(0xFFBCA08A),    // warm sand hint
    navyLight: Color(0xFFF0DBCF),   // warm blush tint
    navyPale: Color(0xFFFAF2EC),    // very light peach-warm
    navy: Color(0xFF5C2D1A),        // deep cognac (primary)
    gold: Color(0xFFC29040),        // antique gold
    goldLight: Color(0xFFFBF3E0),   // gold bg tint
  );

  // ── Dark Palette — Espresso & Dark Cognac ──────────────────────────────────
  static const dark = AppColorScheme(
    bg: Color(0xFF1A0F08),          // near-black espresso background
    surface: Color(0xFF2A1810),     // dark cognac — cards (the luxury dark brown!)
    surfaceAlt: Color(0xFF3A2415),  // dark warm brown — inputs
    border: Color(0xFF503020),      // warm dark border
    borderStrong: Color(0xFF6A4030),
    textPrimary: Color(0xFFF5EDD8), // warm cream
    textBody: Color(0xFFD4B898),    // warm tan
    textSecondary: Color(0xFF9A7A60), // medium warm
    textHint: Color(0xFF5C3D2E),    // muted warm
    navyLight: Color(0xFF3A2415),
    navyPale: Color(0xFF2A1810),
    navy: Color(0xFF5C2D1A),        // same primary cognac
    gold: Color(0xFFD4A848),        // brighter gold for dark mode
    goldLight: Color(0xFF2A1A0A),
  );

  @override
  AppColorScheme copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textBody,
    Color? textSecondary,
    Color? textHint,
    Color? navyLight,
    Color? navyPale,
    Color? navy,
    Color? gold,
    Color? goldLight,
  }) {
    return AppColorScheme(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textBody: textBody ?? this.textBody,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      navyLight: navyLight ?? this.navyLight,
      navyPale: navyPale ?? this.navyPale,
      navy: navy ?? this.navy,
      gold: gold ?? this.gold,
      goldLight: goldLight ?? this.goldLight,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other == null) return this;
    return AppColorScheme(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      navyLight: Color.lerp(navyLight, other.navyLight, t)!,
      navyPale: Color.lerp(navyPale, other.navyPale, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
    );
  }
}

/// Convenience extension — use `context.appColors` anywhere
extension AppColorsContext on BuildContext {
  AppColorScheme get appColors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
