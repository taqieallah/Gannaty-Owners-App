import 'package:flutter/material.dart';

/// Gannaty Design System — Spacing & Radius
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 48;

  /// Standard horizontal screen padding
  static const double screenH = 20.0;

  /// Standard between-section vertical gap
  static const double sectionGap = 24.0;

  // ── Quick EdgeInsets helpers ───────────────────────────────────────────────
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: screenH, vertical: 20);

  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(20);
  static const EdgeInsets tilePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}

/// Gannaty Design System — Border Radius
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 100;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
}
