import '../../core/widgets/adaptive_row.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// FluentTalk brand mark — a gradient squircle holding a speech bubble
/// with a voice waveform and an "Tom" sparkle. Drawn in code so it stays
/// crisp at any size and needs no image assets.
class AppLogo extends StatelessWidget {
  final double size;
  final bool withShadow;

  /// When true, renders the mark in white-on-transparent style (for use on
  /// top of gradient / dark backgrounds).
  final bool inverted;

  /// Corner radius as a fraction of [size] (0 = full-bleed square, used for app icons).
  final double cornerFactor;

  const AppLogo({
    super.key,
    this.size = 48,
    this.withShadow = true,
    this.inverted = false,
    this.cornerFactor = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * cornerFactor),
        boxShadow: withShadow && !inverted
            ? [
                BoxShadow(
                  color: AppColors.brandViolet.withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.14),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(inverted: inverted, cornerFactor: cornerFactor),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool inverted;
  final double cornerFactor;

  _LogoPainter({required this.inverted, this.cornerFactor = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final bgRRect =
        RRect.fromRectAndRadius(rect, Radius.circular(s * cornerFactor));

    // 1. Background squircle
    if (inverted) {
      canvas.drawRRect(
          bgRRect, Paint()..color = Colors.white.withValues(alpha: 0.18));
      canvas.drawRRect(
        bgRRect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.35),
      );
    } else {
      canvas.drawRRect(
        bgRRect,
        Paint()..shader = AppColors.brandGradientVivid.createShader(rect),
      );
      // Glossy highlight
      canvas.save();
      canvas.clipRRect(bgRRect);
      canvas.drawCircle(
        Offset(s * 0.12, s * 0.05),
        s * 0.62,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.28),
              Colors.white.withValues(alpha: 0)
            ],
          ).createShader(Rect.fromCircle(
              center: Offset(s * 0.12, s * 0.05), radius: s * 0.62)),
      );
      canvas.restore();
    }

    // 2. Speech bubble (body + tail drawn separately so windings never cancel)
    final bubblePaint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromLTRBR(
          s * 0.19, s * 0.22, s * 0.81, s * 0.68, Radius.circular(s * 0.17)),
      bubblePaint,
    );
    final tail = Path()
      ..moveTo(s * 0.29, s * 0.58)
      ..lineTo(s * 0.48, s * 0.64)
      ..lineTo(s * 0.285, s * 0.80)
      ..quadraticBezierTo(s * 0.255, s * 0.82, s * 0.258, s * 0.785)
      ..close();
    canvas.drawPath(tail, bubblePaint);

    // 3. Waveform bars inside bubble
    const heights = [0.09, 0.19, 0.27, 0.17, 0.09];
    final barW = s * 0.056;
    final gap = s * 0.088;
    final cy = s * 0.45;
    final startX = s * 0.5 - gap * 2;
    final barPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.brandIndigo, AppColors.brandFuchsia],
      ).createShader(Rect.fromLTWH(startX, 0, gap * 4, s));
    for (var i = 0; i < heights.length; i++) {
      final h = s * heights[i];
      final x = startX + gap * i;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, cy), width: barW, height: h),
          Radius.circular(barW / 2),
        ),
        barPaint,
      );
    }

    // 4. Tom sparkle (4-point star) at top-right
    _drawSparkle(
        canvas, Offset(s * 0.80, s * 0.21), s * 0.11, AppColors.brandAmber);
    _drawSparkle(canvas, Offset(s * 0.90, s * 0.36), s * 0.05,
        Colors.white.withValues(alpha: 0.9));
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Color color) {
    final inner = r * 0.28;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(
          c.dx + inner * 0.3, c.dy - inner * 0.3, c.dx + r, c.dy)
      ..quadraticBezierTo(
          c.dx + inner * 0.3, c.dy + inner * 0.3, c.dx, c.dy + r)
      ..quadraticBezierTo(
          c.dx - inner * 0.3, c.dy + inner * 0.3, c.dx - r, c.dy)
      ..quadraticBezierTo(
          c.dx - inner * 0.3, c.dy - inner * 0.3, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.inverted != inverted ||
      oldDelegate.cornerFactor != cornerFactor;
}

/// Logo mark + "FluentTalk" wordmark.
class AppLogoWordmark extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final bool showAiBadge;
  final bool onDark;

  const AppLogoWordmark({
    super.key,
    this.logoSize = 32,
    this.fontSize = 18,
    this.showAiBadge = false,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveRow(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize, withShadow: !onDark, inverted: onDark),
        SizedBox(width: logoSize * 0.3),
        BrandWordmark(fontSize: fontSize, onDark: onDark),
        if (showAiBadge) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: onDark ? null : AppColors.brandGradient,
              color: onDark ? Colors.white.withValues(alpha: 0.2) : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Tom',
              style: TextStyle(
                fontSize: fontSize * 0.55,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// "Fluent" + gradient "Talk" text.
class BrandWordmark extends StatelessWidget {
  final double fontSize;
  final bool onDark;

  const BrandWordmark({super.key, this.fontSize = 18, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.1,
    );
    return AdaptiveRow(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fluent',
            style: base.copyWith(
                color: onDark ? Colors.white : AppColors.textPrimary)),
        if (onDark)
          Text('Talk',
              style: base.copyWith(color: Colors.white.withValues(alpha: 0.85)))
        else
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                AppColors.brandGradientVivid.createShader(bounds),
            child: Text('Talk', style: base.copyWith(color: Colors.white)),
          ),
      ],
    );
  }
}
