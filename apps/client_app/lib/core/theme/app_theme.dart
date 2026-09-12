import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color cognac = Color(0xFF7A4726);
  static const Color espresso = Color(0xFF1A0F08);
  static const Color ivory = Color(0xFFF7F1E3);
  static const Color sand = Color(0xFFF3E7D6);
  static const Color mist = Color(0xFFFDFBF7);
  static const Color gold = Color(0xFFC29040);
  static const Color danger = Color(0xFFC64040);
  static const Color success = Color(0xFF168267);
  static const Color text = Color(0xFF3A2416);
  static const Color textSoft = Color(0xFF8A6B55);

  static ThemeData get light {
    final textTheme = GoogleFonts.cairoTextTheme();
    final scheme = ColorScheme.fromSeed(
      seedColor: cognac,
      brightness: Brightness.light,
      primary: cognac,
      secondary: gold,
      surface: mist,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ivory,
      textTheme: textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ivory,
        foregroundColor: text,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: mist,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: cognac.withValues(alpha: 0.12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mist,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cognac.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cognac.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cognac, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cognac,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
      ),
      iconTheme: const IconThemeData(color: cognac),
    );
  }

  static ThemeData get dark {
    final textTheme = GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme,
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: cognac,
      brightness: Brightness.dark,
      primary: const Color(0xFFD5A26C),
      secondary: gold,
      surface: const Color(0xFF22160F),
      error: const Color(0xFFFF8C8C),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF140D09),
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFFF7EBDC),
        displayColor: const Color(0xFFF7EBDC),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF140D09),
        foregroundColor: const Color(0xFFF7EBDC),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          color: const Color(0xFFF7EBDC),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF22160F),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF22160F),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD5A26C), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cognac,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFD5A26C)),
    );
  }
}
