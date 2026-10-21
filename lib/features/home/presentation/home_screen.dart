import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/scenario.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_logo.dart';
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.softBackdrop),
        child: SafeArea(
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

                        const SizedBox(height: AppSpacing.xl),

                        // 2. Daily Metrics: Streak & Minutes Goal & Weekly Progress
                        _buildDailyMetrics(state),

                        const SizedBox(height: AppSpacing.xl),

                        // 3. Hero Card: "Your Next Best Lesson" based on weakness
                        RecommendationCard(
                          tag: 'Đề xuất theo điểm yếu',
                          title: state.nextLessonTitle,
                          description: state.nextLessonDesc,
                          timeEstimate: '5 phút',
                          whyRecommended: state.nextLessonWhy,
                          onStart: () => context.push('/practice/scenario/${state.nextLessonScenarioId}'),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // 4. Quick Practice Modes (3 Core Modes: Text, Guided, Realtime)
                        _buildQuickActions(context),

                        const SizedBox(height: AppSpacing.xl),

                        // 5. Micro Insight Card with Evidence (Appendix B8)
                        _buildMicroInsightCard(state),

                        const SizedBox(height: AppSpacing.xxl),

                        // 6. Recommended Scenarios Horizontal Carousel
                        _buildScenarioSection(context, state.recommendedScenarios),

                        const SizedBox(height: AppSpacing.huge),
                      ],
                    ),
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

  Widget _sectionTitle(String text, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildHeader(BuildContext context, HomeDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogoWordmark(logoSize: 30, fontSize: 18),
            const Spacer(),
            _circleIconButton(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không có thông báo mới nào.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Badge(
                smallSize: 8,
                backgroundColor: AppColors.accent,
                child: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            // Gradient ring avatar
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradientVivid,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.secondaryLight,
                  child: Text(
                    state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
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
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
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
          ],
        ),
      ],
    );
  }

  Widget _circleIconButton({required VoidCallback onTap, required Widget child}) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDailyMetrics(HomeDashboardState state) {
    final goalProgress = state.dailyGoalMinutes == 0
        ? 0.0
        : (state.todayMinutes / state.dailyGoalMinutes).clamp(0.0, 1.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Streak Card
          Expanded(
            child: _metricCard(
              iconGradient: AppColors.warmGradient,
              emoji: '🔥',
              value: '${state.streakDays} ngày',
              valueColor: AppColors.textPrimary,
              label: 'Chuỗi liên tục',
              footer: Row(
                children: List.generate(7, (i) {
                  final active = i < state.streakDays.clamp(0, 7);
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: i == 6 ? 0 : 3),
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.warmGradient : null,
                        color: active ? null : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Daily Minutes Goal
          Expanded(
            child: _metricCard(
              iconGradient: AppColors.brandGradient,
              emoji: '⏱️',
              value: '${state.todayMinutes}/${state.dailyGoalMinutes} p',
              valueColor: AppColors.primary,
              label: 'Mục tiêu hôm nay',
              footer: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: goalProgress,
                  minHeight: 5,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required LinearGradient iconGradient,
    required String emoji,
    required String value,
    required Color valueColor,
    required String label,
    required Widget footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconGradient.colors.first.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: valueColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          footer,
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Luyện tập nhanh'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _buildActionItem(
              context: context,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Hỏi AI Text',
              subtitle: 'Nghe AI đọc',
              gradient: AppColors.brandGradient,
              onTap: () => context.push('/practice/text'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildActionItem(
              context: context,
              icon: Icons.mic_none_rounded,
              title: 'Nói theo lượt',
              subtitle: 'Có kịch bản',
              gradient: AppColors.accentGradient,
              onTap: () => context.push('/practice/scenarios'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildActionItem(
              context: context,
              icon: Icons.phone_in_talk_rounded,
              title: 'Gọi thoại',
              subtitle: 'Realtime 2 chiều',
              gradient: AppColors.purpleGradient,
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
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    final color = gradient.colors.first;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
          boxShadow: AppColors.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.cardRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 23),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildMicroInsightCard(HomeDashboardState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8FBF6), Color(0xFFE6F7FD)],
        ),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.glow(AppColors.accent, opacity: 0.25),
            ),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
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
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.microInsightEvidence,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
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

  Widget _buildScenarioSection(BuildContext context, List<Scenario> scenarios) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Tình huống đề xuất',
          trailing: TextButton(
            onPressed: () => context.push('/practice/scenarios'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Xem tất cả'),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 172,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: scenarios.length,
            itemBuilder: (ctx, idx) {
              final scenario = scenarios[idx];
              return _buildScenarioCard(context, scenario, idx);
            },
          ),
        ),
      ],
    );
  }

  static const List<LinearGradient> _cardGradients = [
    AppColors.brandGradient,
    AppColors.accentGradient,
    AppColors.purpleGradient,
    AppColors.warmGradient,
  ];

  Widget _buildScenarioCard(BuildContext context, Scenario scenario, int index) {
    final gradient = _cardGradients[index % _cardGradients.length];

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: AppSpacing.sm, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
        boxShadow: AppColors.softShadow,
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
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.forum_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(child: LevelChip(level: scenario.level)),
                    const Spacer(),
                    const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${scenario.estimatedMinutes} phút',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  scenario.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AI: ${scenario.roleAi} • Bạn: ${scenario.roleUser}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
