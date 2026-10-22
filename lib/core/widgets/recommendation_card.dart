import '../../core/widgets/adaptive_row.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Card for "Your Next Best Lesson" / Coach Recommendation
/// Compliant with Appendix B8 (Screen 06) and B18 (Screen 16)
///
/// Rendered as a vivid gradient hero card so the primary next action stands out.
class RecommendationCard extends StatelessWidget {
  final String tag;
  final String title;
  final String description;
  final String? timeEstimate;
  final String? whyRecommended;
  final VoidCallback? onStart;
  final Color? accentColor;

  const RecommendationCard({
    super.key,
    required this.tag,
    required this.title,
    required this.description,
    this.timeEstimate,
    this.whyRecommended,
    this.onStart,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = accentColor == null
        ? AppColors.brandGradientVivid
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor!,
              Color.lerp(accentColor!, Colors.black, 0.25)!
            ],
          );
    final glowColor = accentColor ?? AppColors.brandViolet;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.cardRadiusLarge,
        boxShadow: AppColors.glow(glowColor, opacity: 0.3),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadiusLarge,
        child: Stack(
          children: [
            // Decorative orbs
            Positioned(
              top: -40,
              right: -30,
              child: _orb(140, 0.12),
            ),
            Positioned(
              bottom: -50,
              right: 60,
              child: _orb(110, 0.08),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Icon(Icons.auto_awesome_rounded,
                  size: 40, color: Colors.white.withValues(alpha: 0.22)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveRow(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.round),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: AdaptiveRow(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 14, color: AppColors.brandAmber),
                            const SizedBox(width: 4),
                            Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (timeEstimate != null)
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.85)),
                            const SizedBox(width: 4),
                            Text(
                              timeEstimate!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(right: 36),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.45,
                    ),
                  ),
                  if (whyRecommended != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_rounded,
                              size: 15, color: AppColors.brandAmber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              whyRecommended!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.92),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.textScalerOf(context).scale(48),
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: accentColor ?? AppColors.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonRadius,
                        ),
                        elevation: 0,
                      ),
                      child: const AdaptiveRow(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bắt đầu ngay',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
