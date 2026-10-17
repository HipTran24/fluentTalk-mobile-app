import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// IELTS-Inspired Rubric Score Axis Card
/// Compliant with ESP-PLAN-001 Appendix A5 & B15
class ScoreAxisCard extends StatefulWidget {
  final DimensionScore score;

  const ScoreAxisCard({
    super.key,
    required this.score,
  });

  @override
  State<ScoreAxisCard> createState() => _ScoreAxisCardState();
}

class _ScoreAxisCardState extends State<ScoreAxisCard> {
  bool _isExpanded = false;

  Color _getBandColor(double? band) {
    if (band == null) return AppColors.textMuted;
    if (band >= 7.0) return AppColors.success;
    if (band >= 5.5) return AppColors.primary;
    if (band >= 4.0) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final bandColor = _getBandColor(widget.score.estimatedBand);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            title: Text(
              widget.score.dimension.labelEn,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              widget.score.dimension.labelVi,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bandColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.round),
                    border: Border.all(color: bandColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.score.displayBand,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: bandColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.score.feedbackVi,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (widget.score.evidenceSnippets.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Dẫn chứng thực tế:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.score.evidenceSnippets.map(
                      (snippet) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• "$snippet"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
