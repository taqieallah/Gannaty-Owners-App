import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Owner-app theme aligned with the ERP's "gold" identity: a warm amber accent,
/// cool off-white surfaces, flat white bordered cards, navy text and Cairo type.
/// Constant names are kept for backwards compatibility; only the values moved.
class AppTheme {
  AppTheme._();

  // ── Brand / accent ──────────────────────────────────────────────────────
  static const Color cognac = Color(0xFFB45309); // primary accent (ERP gold)
  static const Color gold = Color(0xFFB45309);
  static const Color espresso = Color(0xFF7A3D06); // deep amber (accents)

  // ── Surfaces ────────────────────────────────────────────────────────────
  static const Color ivory = Color(0xFFF6F7FA); // scaffold background
  static const Color mist = Color(0xFFFFFFFF); // cards / surface
  static const Color sand = Color(0xFFF1F3F7); // surfaceLow / fills
  static const Color surfaceHigh = Color(0xFFE8ECF3);

  // ── Ink ─────────────────────────────────────────────────────────────────
  static const Color text = Color(0xFF0F1729); // primary text (navy)
  static const Color textSoft = Color(0xFF5B6675); // secondary text
  static const Color muted = Color(0xFF8A93A3);

  // ── Lines ───────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFFDDE2EB);
  static const Color outlineSoft = Color(0xFFEAEDF3);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF047857);
  static const Color danger = Color(0xFFB91C1C);
  static const Color warning = Color(0xFFB45309);
  static const Color info = Color(0xFF2563EB);

  // Deep navy used for the balance hero (premium, ERP nav tone).
  static const Color heroTop = Color(0xFF16213A);
  static const Color heroBottom = Color(0xFF0F1729);

  static const BorderRadius rCard = BorderRadius.all(Radius.circular(14));
  static const BorderRadius rField = BorderRadius.all(Radius.circular(12));
  static const BorderRadius rPanel = BorderRadius.all(Radius.circular(18));

  static ThemeData get light {
    final base = GoogleFonts.cairoTextTheme();
    final scheme = ColorScheme.fromSeed(
      seedColor: cognac,
      brightness: Brightness.light,
    ).copyWith(
      primary: cognac,
      onPrimary: Colors.white,
      secondary: espresso,
      surface: mist,
      onSurface: text,
      onSurfaceVariant: textSoft,
      error: danger,
      outline: outline,
      outlineVariant: outlineSoft,
    );
    return _build(
      scheme: scheme,
      textTheme: base.apply(bodyColor: text, displayColor: text),
      scaffold: ivory,
      surface: mist,
      fill: sand,
      onSurface: text,
      onSurfaceVariant: textSoft,
      outline: outline,
      outlineVariant: outlineSoft,
    );
  }

  static ThemeData get dark {
    const dText = Color(0xFFE7ECF5);
    const dTextSoft = Color(0xFF9DA9BC);
    const dBg = Color(0xFF0B1120);
    const dSurface = Color(0xFF111827);
    const dFill = Color(0xFF0E1626);
    const dOutline = Color(0xFF293449);
    const dOutlineSoft = Color(0xFF1F2A3D);
    const dAccent = Color(0xFFE3A857);
    final base = GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme);
    final scheme = ColorScheme.fromSeed(
      seedColor: dAccent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: dAccent,
      onPrimary: const Color(0xFF3A2A0F),
      secondary: dAccent,
      surface: dSurface,
      onSurface: dText,
      onSurfaceVariant: dTextSoft,
      error: const Color(0xFFF87171),
      outline: dOutline,
      outlineVariant: dOutlineSoft,
    );
    return _build(
      scheme: scheme,
      textTheme: base.apply(bodyColor: dText, displayColor: dText),
      scaffold: dBg,
      surface: dSurface,
      fill: dFill,
      onSurface: dText,
      onSurfaceVariant: dTextSoft,
      outline: dOutline,
      outlineVariant: dOutlineSoft,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required Color scaffold,
    required Color surface,
    required Color fill,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required Color outlineVariant,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.cairo(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: rCard,
          side: BorderSide(color: outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: outlineVariant, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: rField,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: rField,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: rField,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(color: onSurfaceVariant),
        hintStyle: GoogleFonts.cairo(color: onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800),
          shape: const RoundedRectangleBorder(borderRadius: rField),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800),
          shape: const RoundedRectangleBorder(borderRadius: rField),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: outline),
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: rField),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fill,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: outlineVariant),
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: scheme.primary),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: rPanel),
      ),
    );
  }
}
