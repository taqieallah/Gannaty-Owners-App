import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_color_scheme.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  // Legacy aliases — keep for backward compat
  static const Color darkBlue = AppColors.navy;
  static const Color accentBlue = AppColors.navyMid;
  static const Color lightBlue = AppColors.navyLight;
  static const Color white = AppColors.white;

  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static ThemeData get light => _build(
        colors: AppColorScheme.light,
        brightness: Brightness.light,
        statusIconBrightness: Brightness.light,
      );

  // ── DARK THEME ────────────────────────────────────────────────────────────
  static ThemeData get dark => _build(
        colors: AppColorScheme.dark,
        brightness: Brightness.dark,
        statusIconBrightness: Brightness.light,
      );

  // ── SHARED BUILDER ────────────────────────────────────────────────────────
  static ThemeData _build({
    required AppColorScheme colors,
    required Brightness brightness,
    required Brightness statusIconBrightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final cairoBase = GoogleFonts.cairoTextTheme();

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      primaryContainer: colors.navyLight,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.navyMid,
      onSecondary: Colors.white,
      secondaryContainer: colors.navyPale,
      onSecondaryContainer: AppColors.navy,
      tertiary: colors.gold,
      onTertiary: Colors.white,
      tertiaryContainer: colors.goldLight,
      onTertiaryContainer: AppColors.navy,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.surfaceAlt,
      outline: colors.border,
      outlineVariant: colors.borderStrong,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isDark ? colors.surface : AppColors.navy,
      onInverseSurface: isDark ? colors.textPrimary : Colors.white,
      inversePrimary: colors.navyLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,

      // ── ThemeExtension (our dynamic colors) ──────────────────────────────
      extensions: [colors],

      // ── Typography ────────────────────────────────────────────────────────
      textTheme: cairoBase.copyWith(
        displayLarge: cairoBase.displayLarge
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: cairoBase.displayMedium
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
        displaySmall: cairoBase.displaySmall
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: cairoBase.headlineLarge
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: cairoBase.headlineMedium
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: cairoBase.headlineSmall
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: cairoBase.titleLarge
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: cairoBase.titleMedium
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: cairoBase.titleSmall
            ?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500),
        bodyLarge:
            cairoBase.bodyLarge?.copyWith(color: colors.textBody),
        bodyMedium:
            cairoBase.bodyMedium?.copyWith(color: colors.textBody),
        bodySmall:
            cairoBase.bodySmall?.copyWith(color: colors.textSecondary),
        labelLarge: cairoBase.labelLarge?.copyWith(
            color: colors.textSecondary, fontWeight: FontWeight.w600),
        labelMedium: cairoBase.labelMedium
            ?.copyWith(color: colors.textSecondary),
        labelSmall:
            cairoBase.labelSmall?.copyWith(color: colors.textHint),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusIconBrightness,
          systemNavigationBarColor: colors.surface,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Inputs ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(
            color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.cairo(
            color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600),
        hintStyle:
            GoogleFonts.cairo(color: colors.textHint, fontSize: 14),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        errorStyle:
            GoogleFonts.cairo(color: AppColors.error, fontSize: 12),
      ),

      // ── Buttons ───────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.border,
          disabledForegroundColor: colors.textHint,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.cairo(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w500),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.navyLight,
        indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.navy, size: 22);
          }
          return IconThemeData(color: colors.textHint, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.cairo(fontSize: 11, height: 1.2);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
                color: AppColors.navy, fontWeight: FontWeight.w700);
          }
          return base.copyWith(color: colors.textHint);
        }),
        height: 68,
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.navy,
        unselectedLabelColor: colors.textHint,
        indicatorColor: AppColors.navy,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: colors.border,
        labelStyle:
            GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w400),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        extendedTextStyle: GoogleFonts.cairo(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceAlt,
        selectedColor: colors.navyLight,
        labelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: colors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide(color: colors.border),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? Colors.white
            : colors.borderStrong),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? AppColors.navy
            : colors.surfaceAlt),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: GoogleFonts.cairo(
            fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
        contentTextStyle: GoogleFonts.cairo(
            fontSize: 14, color: colors.textBody, height: 1.5),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceAlt : AppColors.navy,
        contentTextStyle:
            GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        elevation: 4,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
          color: colors.border, thickness: 1, space: 1),

      // ── List Tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: colors.surface,
      ),

      // ── Progress ──────────────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.navy,
        linearTrackColor: colors.navyLight,
        circularTrackColor: colors.navyLight,
      ),

      iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
    );
  }
}
