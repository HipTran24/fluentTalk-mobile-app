import '../../../core/widgets/adaptive_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/coach_memory.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import 'controllers/coach_controller.dart';

/// Screen 18 — Weekly Learning Plan
/// Compliant with ESP-PLAN-001 Appendix B20
class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(weeklyPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lộ trình học 7 ngày'),
      ),
      body: SafeArea(
        child: planAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Text('Lỗi tải lộ trình: $err'),
          ),
          data: (planItems) => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: planItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = planItems[index];
              return _buildPlanCard(context, item);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WeeklyPlanItem item) {
    VoidCallback onTapAction;
    if (item.title.contains('Kịch bản') ||
        item.title.contains('nhà hàng') ||
        item.title.contains('Phỏng vấn')) {
      onTapAction = () => context.push('/practice/scenario/sc_travel_01');
    } else if (item.title.contains('Drill') ||
        item.title.contains('Quá khứ') ||
        item.title.contains('Trọng âm')) {
      onTapAction = () => context.push('/coach/drill/drill_past_tense');
    } else if (item.title.contains('Cuộc gọi') ||
        item.title.contains('du lịch')) {
      onTapAction = () => context.push('/practice/realtime/weekend_talk');
    } else if (item.title.contains('từ vựng')) {
      onTapAction = () => context.push('/profile/vocabulary');
    } else {
      onTapAction = () => context.push('/coach');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: item.isToday ? AppColors.primary : AppColors.border,
          width: item.isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 8),
          onTap: onTapAction,
          leading: Icon(
            item.isCompleted
                ? Icons.check_circle_rounded
                : (item.isToday
                    ? Icons.play_circle_fill_rounded
                    : Icons.radio_button_unchecked_rounded),
            color: item.isCompleted
                ? AppColors.success
                : (item.isToday ? AppColors.primary : AppColors.textMuted),
            size: 30,
          ),
          title: AdaptiveRow(
            children: [
              Text(
                item.dayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: item.isToday ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              if (item.isToday) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Hôm nay',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.activityType,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
