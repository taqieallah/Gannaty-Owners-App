import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_type.dart';

/// The Gannaty owner-app theme: deep navy brand, warm copper accent, calm warm
/// off-white surfaces, IBM Plex Sans Arabic. Legacy constant names are kept as
/// aliases so screens compile while they are migrated to [AppColors].
class AppTheme {
  AppTheme._();

  // ── Legacy aliases (repointed to the new brand) ──────────────────────────
  static const Color cognac = AppColors.copper; // accent
  static const Color gold = AppColors.copper;
  static const Color espresso = AppColors.copperSoft;
  static const Color ivory = AppColors.bg;
  static const Color mist = AppColors.surface;
  static const Color sand = AppColors.surfaceAlt;
  static const Color text = AppColors.ink;
  static const Color textSoft = AppColors.inkSoft;
  static const Color muted = AppColors.muted;
  static const Color outline = AppColors.line;
  static const Color outlineSoft = AppColors.lineSoft;
  static const Color success = AppColors.success;
  static const Color danger = AppColors.danger;
  static const Color warning = AppColors.amber;
  static const Color info = AppColors.info;
  static const Color heroTop = AppColors.navySoft;
  static const Color heroBottom = AppColors.navyDeep;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? AppColors.dBg : AppColors.bg;
    final surface = dark ? AppColors.dSurface : AppColors.surface;
    final fill = dark ? AppColors.dSurfaceAlt : AppColors.surfaceAlt;
    final ink = dark ? AppColors.dInk : AppColors.ink;
    final inkSoft = dark ? AppColors.dInkSoft : AppColors.inkSoft;
    final line = dark ? AppColors.dLine : AppColors.line;
    final lineSoft = dark ? AppColors.dLine : AppColors.lineSoft;
    final accent = dark ? AppColors.dCopper : AppColors.copper;
    final primary = dark ? AppColors.dInk : AppColors.navy;

    final scheme = ColorScheme(
      brightness: b,
      primary: primary,
      onPrimary: dark ? AppColors.navyDeep : Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: inkSoft,
      error: AppColors.danger,
      onError: Colors.white,
      outline: line,
      outlineVariant: lineSoft,
      tertiary: accent,
    );
    final textTheme = AppType.textTheme(b);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
            color: ink, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: Radii.md, side: BorderSide(color: line)),
      ),
      dividerTheme: DividerThemeData(color: lineSoft, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: Radii.sm, borderSide: BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: Radii.sm, borderSide: BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: Radii.sm,
            borderSide: BorderSide(color: accent, width: 1.5)),
        labelStyle: TextStyle(color: inkSoft),
        hintStyle: TextStyle(color: AppColors.muted),
        prefixIconColor: inkSoft,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          elevation: 0,
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: Radii.md),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: Radii.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: line),
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: Radii.md),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fill,
        shape: const RoundedRectangleBorder(borderRadius: Radii.pill),
        side: BorderSide(color: lineSoft),
        labelStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      iconTheme: IconThemeData(color: inkSoft),
      listTileTheme: ListTileThemeData(
        iconColor: inkSoft,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: Radii.lg),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: GoogleFonts.ibmPlexSansArabic(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.md),
      ),
    );
  }
}
