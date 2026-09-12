import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographic system — IBM Plex Sans Arabic throughout, one consistent scale.
/// Financial values get a tabular, high-hierarchy treatment.
class AppType {
  AppType._();

  static TextTheme textTheme(Brightness b) {
    final ink = b == Brightness.dark ? AppColors.dInk : AppColors.ink;
    final soft = b == Brightness.dark ? AppColors.dInkSoft : AppColors.inkSoft;
    final base = GoogleFonts.ibmPlexSansArabicTextTheme(
      b == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w700, color: ink, height: 1.15),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, color: ink, height: 1.2),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700, color: ink, height: 1.2),
      titleLarge: base.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, color: ink, fontSize: 18),
      titleMedium: base.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700, color: ink, fontSize: 15.5),
      titleSmall: base.titleSmall
          ?.copyWith(fontWeight: FontWeight.w600, color: ink),
      bodyLarge: base.bodyLarge?.copyWith(color: ink, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(color: ink, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(color: soft, height: 1.45),
      labelLarge:
          base.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: ink),
      labelMedium: base.labelMedium
          ?.copyWith(fontWeight: FontWeight.w600, color: soft, letterSpacing: 0.2),
      labelSmall: base.labelSmall
          ?.copyWith(fontWeight: FontWeight.w600, color: soft, letterSpacing: 0.3),
    );
  }

  /// An uppercase-ish section eyebrow / label.
  static TextStyle eyebrow(Color color) => GoogleFonts.ibmPlexSansArabic(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.4,
      );

  /// A large financial value with tabular figures.
  static TextStyle money(
    Color color, {
    double size = 30,
    FontWeight weight = FontWeight.w800,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle num(Color color,
          {double size = 15, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.ibmPlexSansArabic(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
