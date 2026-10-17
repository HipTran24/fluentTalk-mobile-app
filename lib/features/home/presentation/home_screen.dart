import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/scenario.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/recommendation_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'controllers/home_controller.dart';

/// Screen 06 — Home Dashboard
/// Compliant with ESP-PLAN-001 Appendix B8
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeDashboardControllerProvider);
    final controller = ref.read(homeDashboardControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          child: state.isLoading
              ? _buildLoadingSkeleton()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                    vertical: AppSpacing.pageVertical,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Header: Greeting, User Avatar & Level Badge & Bell
                      _buildHeader(context, state),

                      const SizedBox(height: AppSpacing.lg),

                      // 2. Daily Metrics: Streak & Minutes Goal & Weekly Progress
                      _buildDailyMetrics(state),

                      const SizedBox(height: AppSpacing.lg),

                      // 3. Hero Card: "Your Next Best Lesson" based on weakness
                      RecommendationCard(
                        tag: 'Đề xuất theo điểm yếu',
                        title: state.nextLessonTitle,
                        description: state.nextLessonDesc,
                        timeEstimate: '5 phút',
                        whyRecommended: state.nextLessonWhy,
                        onStart: () => context.push('/practice/scenario/${state.nextLessonScenarioId}'),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // 4. Quick Practice Modes (3 Core Modes: Text, Guided, Realtime)
                      _buildQuickActions(context),

                      const SizedBox(height: AppSpacing.lg),

                      // 5. Micro Insight Card with Evidence (Appendix B8)
                      _buildMicroInsightCard(state),

                      const SizedBox(height: AppSpacing.lg),

                      // 6. Recommended Scenarios Horizontal Carousel
                      _buildScenarioSection(context, state.recommendedScenarios),

                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      child: Column(
        children: [
          Row(
            children: [
              ShimmerLoading.circular(size: 48),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: ShimmerLoading(width: double.infinity, height: 40)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: ShimmerLoading.card(height: 70)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: ShimmerLoading.card(height: 70)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ShimmerLoading.card(height: 180),
          const SizedBox(height: AppSpacing.lg),
          ShimmerLoading.card(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HomeDashboardState state) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.secondaryLight,
          child: Text(
            state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.greeting,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      state.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  LevelChip(level: state.userLevel),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không có thông báo mới nào.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Badge(
            smallSize: 8,
            backgroundColor: AppColors.accent,
            child: Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyMetrics(HomeDashboardState state) {
    return Row(
      children: [
        // Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.streakDays} ngày',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Chuỗi liên tục',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Daily Minutes Goal
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('⏱️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.todayMinutes}/${state.dailyGoalMinutes} p',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        'Mục tiêu hôm nay',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Luyện tập nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _buildActionItem(
              context: context,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Hỏi AI Text',
              subtitle: 'Nghe AI đọc',
              color: AppColors.primary,
              onTap: () => context.push('/practice/text'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildActionItem(
              context: context,
              icon: Icons.mic_none_rounded,
              title: 'Nói theo lượt',
              subtitle: 'Có kịch bản',
              color: AppColors.accent,
              onTap: () => context.push('/practice/scenarios'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildActionItem(
              context: context,
              icon: Icons.phone_in_talk_rounded,
              title: 'Gọi thoại',
              subtitle: 'Realtime 2 chiều',
              color: const Color(0xFF9333EA),
              onTap: () => context.push('/practice/realtime/quick_call'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicroInsightCard(HomeDashboardState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentBg,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights, color: Colors.white, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.microInsightTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.microInsightEvidence,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioSection(BuildContext context, List<Scenario> scenarios) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tình huống đề xuất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/practice/scenarios'),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: scenarios.length,
            itemBuilder: (ctx, idx) {
              final scenario = scenarios[idx];
              return _buildScenarioCard(context, scenario);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioCard(BuildContext context, Scenario scenario) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/practice/scenario/${scenario.id}'),
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: LevelChip(level: scenario.level)),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${scenario.estimatedMinutes} phút',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Text(
                  scenario.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'AI: ${scenario.roleAi} • Bạn: ${scenario.roleUser}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
