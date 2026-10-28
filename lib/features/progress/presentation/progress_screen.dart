import '../../../core/widgets/adaptive_row.dart';
import '../../../core/widgets/app_logo.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../feedback/domain/models/feedback_models.dart';
import 'controllers/progress_controller.dart';

/// Screen 14 — Progress & Learning Analytics
/// Compliant with ESP-PLAN-001 Appendix B16
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(progressPeriodProvider);
    final analyticsAsync = ref.watch(progressAnalyticsControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Tiến độ học tập'),
        actions: [
          IconButton(
            onPressed: () => context.push('/progress/history'),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử phiên học',
          ),
        ],
      ),
      body: SafeArea(
        child: analyticsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Text('Lỗi tải dữ liệu tiến độ: $err'),
          ),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.pageVertical,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),
                    const SizedBox(height: AppSpacing.xl),
                    // 1. Time Period Toggle (Tuần này, Tháng này, Tất cả)
                    _buildPeriodToggle(ref, selectedPeriod),

                    const SizedBox(height: AppSpacing.lg),

                    // 2. Overview 3 Stat Cards
                    const Text('Tổng quan',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    _buildStatsGrid(data),

                    const SizedBox(height: AppSpacing.lg),

                    // 3. Speaking Minutes Bar Chart Card
                    _buildChartCard(context, data),

                    const SizedBox(height: AppSpacing.lg),

                    // 4. 4-Axis Rubric Competencies Progress
                    _buildRubricProgress(data),

                    const SizedBox(height: AppSpacing.lg),

                    // 5. History Quick Link Card
                    _buildHistoryShortcutCard(context),

                    const SizedBox(height: AppSpacing.sm),

                    // 6. Educational Disclaimer
                    const Center(
                      child: Text(
                        '* Thang điểm Band 0.0 - 9.0 mang tính chất tham khảo học thuật nội bộ.',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.huge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF202B73), Color(0xFF395EB8)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          AppLogo(size: 48, inverted: true, withShadow: false),
          SizedBox(width: 12),
          Expanded(
              child: Text('FLUENTTALK',
                  style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 1,
                      fontSize: 13,
                      fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 20),
        const Text('Hành trình của bạn',
            style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text('Nhìn lại quá trình luyện tập và tiếp tục tiến bộ cùng Tom.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.5)),
      ]),
    );
  }

  Widget _buildPeriodToggle(WidgetRef ref, int selectedPeriod) {
    final periods = ['Tuần này', 'Tháng này', 'Tất cả'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        children: List.generate(periods.length, (idx) {
          final isSelected = selectedPeriod == idx;
          return Expanded(
            child: InkWell(
              onTap: () =>
                  ref.read(progressPeriodProvider.notifier).state = idx,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  periods[idx],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsGrid(ProgressAnalyticsData data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.timer_outlined,
            iconColor: AppColors.primary,
            value: '${data.totalMinutes}',
            unit: 'phút',
            label: 'Thời lượng nói',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatItem(
            icon: Icons.record_voice_over_outlined,
            iconColor: AppColors.accent,
            value: '${data.totalSessions}',
            unit: 'phiên',
            label: 'Đã hoàn thành',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.deepOrange,
            value: '${data.currentStreak}',
            unit: 'ngày',
            label: 'Chuỗi liên tục',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          AdaptiveRow(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, ProgressAnalyticsData data) {
    final maxMinutes = data.weeklyBars
        .fold<int>(1, (prev, bar) => math.max(prev, bar.minutes));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdaptiveRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thời gian luyện nói mỗi ngày',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Custom Responsive Bar Chart
          SizedBox(
            height: 120 + MediaQuery.textScalerOf(context).scale(40),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 340,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: data.weeklyBars.map((bar) {
                    final heightFactor = maxMinutes > 0
                        ? (bar.minutes / maxMinutes).clamp(0.08, 1.0)
                        : 0.08;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (bar.minutes > 0)
                          Text(
                            '${bar.minutes}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: bar.isToday
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          width: 22,
                          height: 80 * heightFactor,
                          decoration: BoxDecoration(
                            color: bar.isToday
                                ? AppColors.primary
                                : AppColors.secondaryLight,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            border: bar.isToday
                                ? Border.all(color: AppColors.primaryLight)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bar.dayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                bar.isToday ? FontWeight.w700 : FontWeight.w500,
                            color: bar.isToday
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRubricProgress(ProgressAnalyticsData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Các tiêu chí luyện tập',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'So sánh năng lực hiện tại so với tuần trước:',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          ...RubricDimension.values.map((dim) {
            const colors = [
              Color(0xFF315BB5),
              Color(0xFF08796A),
              Color(0xFF8050A4),
              Color(0xFFB35B29)
            ];
            final color = colors[dim.index % colors.length];
            final band = data.currentBands[dim] ?? 5.5;
            final growth = data.bandGrowth[dim] ?? 0.0;
            final percent = (band / 9.0).clamp(0.0, 1.0);

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.16)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dim.labelVi,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Band ${band.toStringAsFixed(1)}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          if (growth > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('+${growth.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success)),
                            ),
                        ]),
                    const SizedBox(height: 9),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: color.withValues(alpha: 0.14),
                            valueColor: AlwaysStoppedAnimation<Color>(color))),
                  ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryShortcutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: AppRadius.cardRadius,
        border:
            Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 4),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.history_rounded, color: Colors.white, size: 20),
          ),
          title: const Text(
            'Xem toàn bộ lịch sử luyện nói',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary),
          ),
          subtitle: const Text(
            'Nghe lại audio và xem chi tiết điểm số từng phiên',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.primary),
          onTap: () => context.push('/progress/history'),
        ),
      ),
    );
  }
}
