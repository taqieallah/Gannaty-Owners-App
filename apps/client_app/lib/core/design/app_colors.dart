import 'package:flutter/material.dart';

/// Gannaty brand palette — deep navy primary, warm copper accent, warm
/// off-white surfaces. One calm, trustworthy, premium system used everywhere.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF101A30); // primary / deep navy
  static const Color sidebar = Color(0xFF111827); // dark navigation sidebar
  static const Color navyDeep = Color(0xFF0C1424); // hero gradient bottom
  static const Color navySoft = Color(0xFF1B2740); // hero gradient top
  static const Color copper = Color(0xFFC46A16); // accent / primary actions
  static const Color copperSoft = Color(0xFFD98A3C);
  static const Color copperTint = Color(0xFFF3E3D5); // light copper wash

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color cream = Color(0xFFF3E8D0); // warm outer background
  static const Color bg = cream; // app background
  static const Color surface = Color(0xFFFFFFFF); // workspace / cards
  static const Color surfaceAlt = Color(0xFFF7F8FA); // light gray fills / inputs
  static const Color surfaceMuted = Color(0xFFEFEFEC);

  // ── Ink ─────────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF111827); // primary text
  static const Color inkSoft = Color(0xFF667085); // secondary text
  static const Color muted = Color(0xFF98A0AC); // captions / disabled

  // ── Lines ───────────────────────────────────────────────────────────────
  static const Color line = Color(0xFFEAEBEE); // borders on white
  static const Color lineSoft = Color(0xFFF1F2F4);
  static const Color lineCream = Color(0xFFE6DABF); // borders on cream

  // ── Financial / status ──────────────────────────────────────────────────
  static const Color success = Color(0xFF00866A); // paid / credit / positive
  static const Color successTint = Color(0xFFDFF1EC);
  static const Color danger = Color(0xFFC62828); // debt / overdue / negative
  static const Color dangerTint = Color(0xFFF8E6E6);
  static const Color amber = Color(0xFFD97706); // pending / warning
  static const Color amberTint = Color(0xFFFBEEDD);
  static const Color info = Color(0xFF2B6CB0);
  static const Color infoTint = Color(0xFFE4EDF6);
  static const Color neutralTint = Color(0xFFEFF1F4);

  // ── Dark mode ─────────────────────────────────────────────────────────────
  static const Color dBg = Color(0xFF0B1622);
  static const Color dSurface = Color(0xFF12212F);
  static const Color dSurfaceAlt = Color(0xFF16283A);
  static const Color dInk = Color(0xFFE9EDF2);
  static const Color dInkSoft = Color(0xFFA3AEBC);
  static const Color dLine = Color(0xFF223547);
  static const Color dCopper = Color(0xFFD08A54);
}
