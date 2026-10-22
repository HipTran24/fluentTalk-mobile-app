import 'package:flutter/material.dart';

/// App Design Tokens - Color Palette
/// Compliant with ESP-PLAN-001 Appendix B1
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF4F46E5); // Indigo (brand #4F46E5)
  static const Color primaryDark = Color(0xFF3F37C9);
  static const Color primaryLight = Color(0xFF8B87F7);
  static const Color secondaryLight = Color(0xFFEEEDFF);

  // Brand gradient stops (Indigo → Violet → Fuchsia)
  static const Color brandIndigo = Color(0xFF4F46E5);
  static const Color brandViolet = Color(0xFF7C3AED);
  static const Color brandFuchsia = Color(0xFFC026D3);
  static const Color brandAmber = Color(0xFFFBBF24);

  // Accent Colors
  static const Color accent = Color(0xFF0D9488); // Teal (#0D9488)
  static const Color accentLight = Color(0xFF14B8A6);
  static const Color accentBg = Color(0xFFECFDF8);
  static const Color purple = Color(0xFF9333EA);

  // Surface & Backgrounds (Light Mode)
  static const Color background =
      Color(0xFFF8FAFC); // Plan surface background (#F8FAFC)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F8);
  static const Color border = Color(0xFFE5E7F0);
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

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandIndigo, brandViolet],
  );

  static const LinearGradient brandGradientVivid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandIndigo, brandViolet, brandFuchsia],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
  );

  /// Soft page backdrop used on hero / onboarding screens.
  static const LinearGradient softBackdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEDEBFF), Color(0xFFF5F6FB)],
    stops: [0.0, 0.55],
  );

  // ---------------------------------------------------------------------------
  // Shadows
  // ---------------------------------------------------------------------------
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF1E1B4B).withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}
