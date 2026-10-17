import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/coach_memory.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import 'controllers/coach_controller.dart';

/// Screen 16 — Personal AI Coach Dashboard
/// Compliant with ESP-PLAN-001 Appendix B18 & COACH-06
class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weaknessesAsync = ref.watch(coachWeaknessesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gia sư AI Coach'),
        actions: [
          IconButton(
            onPressed: () => context.push('/coach/plan'),
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Kế hoạch học tuần',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Coach Avatar & Weekly Insights Speech Bubble
              _buildCoachInsightBubble(),

              const SizedBox(height: AppSpacing.lg),

              // 2. Weekly Plan Shortcut Banner
              _buildWeeklyPlanBanner(context),

              const SizedBox(height: AppSpacing.lg),

              // 3. 3 Focus Areas This Week (Prioritized Weaknesses)
              const Text(
                '3 Trọng tâm tuần này của bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Trích xuất tự động từ các câu nói thực tế trong các phiên đàm thoại:',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),

              weaknessesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => Text('Lỗi tải dữ liệu: $err'),
                data: (items) => Column(
                  children: items.map((w) => _buildWeaknessItemCard(context, w)).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 4. Algorithm Transparency (COACH-06 Compliance)
              _buildTransparencyCard(),

              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachInsightBubble() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.psychology, color: Colors.white, size: 28),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach Emma (Trí nhớ dài hạn)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tôi nhận thấy bạn đã phản xạ tự tin hơn rất nhiều khi chào hỏi! Tuy nhiên, bạn thường quên chia thì Quá khứ đơn khi kể lại trải nghiệm. Hãy luyện ngay bài tập 3 phút dưới đây nhé.',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlanBanner(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardRadius,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(Icons.event_note_rounded, color: Colors.white),
        ),
        title: const Text(
          'Lộ trình học cá nhân hóa 7 ngày',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14.5),
        ),
        subtitle: const Text(
          'Hôm nay: Thứ Ba • Bài tập sửa thì Quá khứ đơn',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
        onTap: () => context.push('/coach/plan'),
      ),
    );
  }

  Widget _buildWeaknessItemCard(BuildContext context, WeaknessItem item) {
    Color priorityColor;
    String priorityText;
    if (item.impact >= 0.8) {
      priorityColor = AppColors.error;
      priorityText = 'Ưu tiên cao';
    } else if (item.impact >= 0.65) {
      priorityColor = AppColors.warning;
      priorityText = 'Trung bình';
    } else {
      priorityColor = AppColors.accent;
      priorityText = 'Cải thiện';
    }

    String drillId;
    if (item.id == 'w_01') {
      drillId = 'drill_past_tense';
    } else if (item.id == 'w_02') {
      drillId = 'drill_connectors';
    } else {
      drillId = 'drill_stress';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.description,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priorityText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: priorityColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.analytics_outlined, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bằng chứng: ${item.evidence}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/coach/drill/$drillId'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Bắt đầu Drill 3p', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransparencyCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 20, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vì sao AI đề xuất các bài học này? (COACH-06)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Gia sư AI đối chiếu lỗi ngữ pháp lặp lại, độ ngập ngừng âm thanh và vốn từ vựng của bạn qua các phiên gần nhất để xếp thứ tự ưu tiên các bài tập cần khắc phục trước.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
