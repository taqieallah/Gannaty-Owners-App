import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.isArabic,
  });

  final ThemeMode themeMode;
  final bool isArabic;

  Locale get locale => Locale(isArabic ? 'ar' : 'en');
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? isArabic,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      isArabic: isArabic ?? this.isArabic,
    );
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

class AppSettingsController extends AsyncNotifier<AppSettings> {
  static const _themeKey = 'client_theme_mode';
  static const _langKey = 'client_is_arabic';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? ThemeMode.light.name;
    final isArabic = prefs.getBool(_langKey) ?? true;

    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.light,
      ),
      isArabic: isArabic,
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode.name);
    state = AsyncData((state.value ?? _fallback).copyWith(themeMode: themeMode));
  }

  Future<void> setLanguage(bool isArabic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_langKey, isArabic);
    state = AsyncData((state.value ?? _fallback).copyWith(isArabic: isArabic));
  }

  AppSettings get _fallback => const AppSettings(
        themeMode: ThemeMode.light,
        isArabic: true,
      );
}
