import 'package:flutter/material.dart';

/// Border Radii Tokens
/// Compliant with ESP-PLAN-001 Appendix B1
class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 14.0; // Button radius
  static const double input = 14.0; // Input fields radius
  static const double inputLarge = 16.0;
  static const double lg = 18.0; // Card radius standard
  static const double xl = 24.0; // Card radius large
  static const double round = 999.0;

  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(input));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardRadiusLarge = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheetRadius = BorderRadius.vertical(top: Radius.circular(28));
}
