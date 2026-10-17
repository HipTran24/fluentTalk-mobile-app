import 'package:flutter/material.dart';

/// App Design Tokens - Color Palette
/// Compliant with ESP-PLAN-001 Appendix B1
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondaryLight = Color(0xFFEEF2FF);

  // Accent Colors
  static const Color accent = Color(0xFF0D9488); // Teal
  static const Color accentLight = Color(0xFF14B8A6);
  static const Color accentBg = Color(0xFFF0FDFA);

  // Surface & Backgrounds (Light Mode)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFCBD5E1);

  // Text Colors (Light Mode)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // Status & Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFE0F2FE);

  // Dark Theme Tokens (Appendix B1: Dark mode tokens riêng, không chỉ đảo màu)
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Realtime Audio Mode Canvas (Screen 12 Call Surface)
  static const Color callSurface = Color(0xFF0F172A);
  static const Color userWaveform = Color(0xFF0D9488);
  static const Color aiWaveform = Color(0xFF818CF8);
}
