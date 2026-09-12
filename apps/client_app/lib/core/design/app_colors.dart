import 'package:flutter/material.dart';

/// Gannaty brand palette — deep navy primary, warm copper accent, warm
/// off-white surfaces. One calm, trustworthy, premium system used everywhere.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF0E2740); // primary brand
  static const Color navyDeep = Color(0xFF0A1E33); // hero / headers
  static const Color navySoft = Color(0xFF1C3A57);
  static const Color copper = Color(0xFFB4652A); // accent / primary actions
  static const Color copperSoft = Color(0xFFC98A5C);
  static const Color copperTint = Color(0xFFF6EDE4); // copper wash fills

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF5F4F1); // app background (warm gray)
  static const Color surface = Color(0xFFFFFFFF); // cards / sheets
  static const Color surfaceAlt = Color(0xFFFAF9F6); // subtle fills / inputs
  static const Color surfaceMuted = Color(0xFFEFEEE9);

  // ── Ink ─────────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF14263D); // primary text
  static const Color inkSoft = Color(0xFF5A6675); // secondary text
  static const Color muted = Color(0xFF8C94A1); // captions / disabled

  // ── Lines ───────────────────────────────────────────────────────────────
  static const Color line = Color(0xFFE7E4DD);
  static const Color lineSoft = Color(0xFFF0EEE9);

  // ── Financial / status ──────────────────────────────────────────────────
  static const Color success = Color(0xFF1F7A54); // paid / credit / positive
  static const Color successTint = Color(0xFFE6F2EC);
  static const Color danger = Color(0xFFC0392B); // debt / overdue / negative
  static const Color dangerTint = Color(0xFFF7E7E4);
  static const Color amber = Color(0xFFC0891D); // pending / warning
  static const Color amberTint = Color(0xFFF7EFDC);
  static const Color info = Color(0xFF2B6CB0);
  static const Color infoTint = Color(0xFFE4EDF6);
  static const Color neutralTint = Color(0xFFEDEFF2);

  // ── Dark mode ─────────────────────────────────────────────────────────────
  static const Color dBg = Color(0xFF0B1622);
  static const Color dSurface = Color(0xFF12212F);
  static const Color dSurfaceAlt = Color(0xFF16283A);
  static const Color dInk = Color(0xFFE9EDF2);
  static const Color dInkSoft = Color(0xFFA3AEBC);
  static const Color dLine = Color(0xFF223547);
  static const Color dCopper = Color(0xFFD08A54);
}
