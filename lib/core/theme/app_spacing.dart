import 'package:flutter/material.dart';

/// 8-point Grid Spacing System
/// Compliant with ESP-PLAN-001 Appendix B1
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;

  // Page level paddings
  static const double pageHorizontal = 20.0;
  static const double pageHorizontalWide = 24.0;
  static const double pageVertical = 16.0;

  // Maximum content width constraint on phone (Appendix B1)
  static const double maxContentWidth = 480.0;

  // Minimum touch target sizes
  static const double minTouchTarget = 48.0;
  static const double buttonHeightMin = 48.0;
  static const double buttonHeightStandard = 52.0;

  // Common Insets
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageVertical,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xl);
}
