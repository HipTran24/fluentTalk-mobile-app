import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/score_axis_card.dart';
import '../domain/models/feedback_models.dart';
import 'controllers/session_summary_controller.dart';

/// Screen 13 — Session Summary / Speaking Rubric Report
/// Compliant with ESP-PLAN-001 Appendix A5 & B15
class SessionSummaryScreen extends ConsumerWidget {
  final String sessionId;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(sessionSummaryControllerProvider(sessionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Báo cáo kết quả phiên'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Đóng báo cáo',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SafeArea(
        child: reportAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: AppSpacing.md),
                Text(
                  'AI đang tổng hợp và phân tích báo cáo Rubric...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          error: (err, stack) => Center(
            child: EmptyStateWidget(
              title: 'Không thể tải báo cáo',
              description: 'Đã xảy ra lỗi khi tạo dữ liệu phân tích: $err',
              icon: Icons.error_outline_rounded,
              actionText: 'Quay lại',
              onAction: () => context.pop(),
            ),
          ),
          data: (report) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.pageVertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Overview Summary
                _buildHeroOverview(context, report),

                const SizedBox(height: AppSpacing.lg),

                // 2. Educational Disclaimer Banner (AGENT-16 Rule)
                _buildDisclaimerBanner(),

                const SizedBox(height: AppSpacing.lg),

                // 3. 4-Axis Rubric Evaluations
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đánh giá 4 tiêu chí năng lực',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    LevelChip(level: report.cefrLevel),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dựa trên chuẩn phân tích ngữ liệu và âm học đối chiếu.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Render 4 ScoreAxisCards
                ...report.dimensionScores.map((score) => ScoreAxisCard(score: score)),

                const SizedBox(height: AppSpacing.lg),

                // 4. Corrections Before -> After
                _buildCorrectionSection(report),

                const SizedBox(height: AppSpacing.lg),

                // 5. Coach Emma Personalized Advice Card
                _buildCoachAdviceCard(report),

                const SizedBox(height: AppSpacing.xl),

                // 6. Action CTAs
                PrimaryButton(
                  text: report.recommendedDrillTitle,
                  icon: Icons.bolt_rounded,
                  onPressed: () => context.push('/coach/drill/${report.recommendedDrillId}'),
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  text: 'Về trang chủ',
                  icon: Icons.home_rounded,
                  onPressed: () => context.go('/home'),
                ),

                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroOverview(BuildContext context, SessionReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          const Text(
            'Hoàn thành phiên luyện tập!',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.scenarioTitle} • ${report.mode.title}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'Thời lượng: ${report.formattedDuration} • ${report.turnsCount} lượt tương tác',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),

          // Big Overall Score Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.round),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Band ${report.overallBand.toStringAsFixed(1)} (Tham khảo)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft warm amber
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tuyên bố học thuật: Điểm số Rubric được ước tính bởi mô hình ngôn ngữ và phân tích ngữ âm nhằm mục đích hỗ trợ học tập cá nhân hóa. Kết quả không thay thế chứng chỉ khảo thí chính thức (IELTS/CEFR).',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionSection(SessionReport report) {
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
          const Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Phân tích sửa lỗi Trước ➔ Sau',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Học từ chính các câu nói thực tế của bạn trong phiên:',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),

          ...report.keyCorrections.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Before (User original)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bạn đã nói: "${item.original}"',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // After (Native suggestion)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.successBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đề xuất tự nhiên: "${item.suggested}"',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lý do: ${item.explanationVi}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCoachAdviceCard(SessionReport report) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.psychology, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lời khuyên từ Coach Emma:',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.coachAdviceVi,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
