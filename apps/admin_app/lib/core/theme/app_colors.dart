import 'package:flutter/material.dart';

/// Gannaty Design System — Luxury Warm Palette
/// Cognac & Champagne — premium residential compound theme
class AppColors {
  AppColors._();

  // ── Primary Brand (Deep Cognac / Espresso Brown) ───────────────────────────
  /// Deep cognac — primary CTA, AppBar, FAB, selected nav
  static const Color navy = Color(0xFF5C2D1A);

  /// Medium cognac — hover / pressed states
  static const Color navyMid = Color(0xFF7A4432);

  /// Warm blush tint — chip bg, nav indicators
  static const Color navyLight = Color(0xFFF0DBCF);

  /// Very light peach-warm — subtle surface tints
  static const Color navyPale = Color(0xFFFAF2EC);

  // ── Accent ────────────────────────────────────────────────────────────────
  /// Antique gold — currency figures, settlement totals, highlights
  static const Color gold = Color(0xFFC29040);

  /// Gold background tint
  static const Color goldLight = Color(0xFFFBF3E0);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  /// App scaffold background — warm parchment beige
  static const Color bg = Color(0xFFF4ECDA);

  /// Card / dialog surface — warm ivory
  static const Color surface = Color(0xFFFFFEF8);

  /// Secondary surface — input fill, avatar bg
  static const Color surfaceAlt = Color(0xFFF5EBDC);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE5D5B0);
  static const Color borderStrong = Color(0xFFCEB98A);

  // ── Text ──────────────────────────────────────────────────────────────────
  /// Deep espresso — headings, card titles
  static const Color textPrimary = Color(0xFF2C1810);

  /// Warm brown — body paragraphs
  static const Color textBody = Color(0xFF5A3828);

  /// Warm clay — labels, secondary info
  static const Color textSecondary = Color(0xFF8A6B55);

  /// Warm sand — placeholders, hints
  static const Color textHint = Color(0xFFBCA08A);

  // ── Semantic: Success ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF1B7A5E);
  static const Color successLight = Color(0xFFEBF7F3);
  static const Color successBorder = Color(0xFFB2DDD3);

  // ── Semantic: Warning ─────────────────────────────────────────────────────
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3E2);
  static const Color warningBorder = Color(0xFFFAD28B);

  // ── Semantic: Error ───────────────────────────────────────────────────────
  static const Color error = Color(0xFFC53030);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFF5BABA);

  // ── Semantic: Info ────────────────────────────────────────────────────────
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFD7FF);

  // ── Pure White ────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
}
