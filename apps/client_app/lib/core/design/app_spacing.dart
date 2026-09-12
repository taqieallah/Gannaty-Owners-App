import 'package:flutter/material.dart';

/// 4/8pt spacing scale + shared radii. Use these instead of ad-hoc numbers so
/// rhythm stays consistent across every screen.
class Gap {
  Gap._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  static const SizedBox h4 = SizedBox(height: 4);
  static const SizedBox h8 = SizedBox(height: 8);
  static const SizedBox h12 = SizedBox(height: 12);
  static const SizedBox h16 = SizedBox(height: 16);
  static const SizedBox h20 = SizedBox(height: 20);
  static const SizedBox h24 = SizedBox(height: 24);
  static const SizedBox h32 = SizedBox(height: 32);
  static const SizedBox w4 = SizedBox(width: 4);
  static const SizedBox w8 = SizedBox(width: 8);
  static const SizedBox w12 = SizedBox(width: 12);
  static const SizedBox w16 = SizedBox(width: 16);
}

class Radii {
  Radii._();
  static const BorderRadius sm = BorderRadius.all(Radius.circular(10));
  static const BorderRadius md = BorderRadius.all(Radius.circular(14));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(18));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// The maximum content width on wide screens, so desktop/tablet content stays
/// readable and centered rather than stretched edge-to-edge.
const double kContentMaxWidth = 720;

/// Breakpoint helpers.
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;
bool isTablet(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w >= 600 && w < 900;
}
