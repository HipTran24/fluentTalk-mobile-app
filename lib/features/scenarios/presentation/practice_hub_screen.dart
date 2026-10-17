import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Screen 07 — Practice Hub / Mode Selection
/// Compliant with ESP-PLAN-001 Appendix B9
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Luyện tập phản xạ'),
        actions: [
          IconButton(
            onPressed: () => context.push('/practice/scenarios'),
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Kho kịch bản',
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
              // Network & Hardware Readiness Status
              _buildReadinessBar(),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Chọn phương thức luyện',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lựa chọn chế độ phù hợp với không gian và thời gian của bạn',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Mode 1: Ask & Listen (Text to Voice)
              _buildModeHeroCard(
                context,
                title: 'Hỏi bằng Text, Nghe AI nói',
                subtitle: 'Gõ câu hỏi tiếng Anh hoặc Việt, AI sẽ phát âm phản hồi tự nhiên.',
                duration: '1-3 phút',
                tag: 'Yên tĩnh / Nơi đông người',
                icon: Icons.chat_bubble_rounded,
                accentColor: AppColors.primary,
                onTap: () => context.push('/practice/text'),
              ),

              const SizedBox(height: AppSpacing.md),

              // Mode 2: Guided Speaking (Turn-based)
              _buildModeHeroCard(
                context,
                title: 'Luyện nói theo lượt (Guided)',
                subtitle: 'Hội thoại nhập vai từng câu với AI. Xem transcript và nhận gợi ý tức thì.',
                duration: '5-10 phút',
                tag: 'Phù hợp người mới A1-B1',
                icon: Icons.record_voice_over_rounded,
                accentColor: AppColors.accent,
                onTap: () => context.push('/practice/scenarios'),
              ),

              const SizedBox(height: AppSpacing.md),

              // Mode 3: Realtime Voice Call
              _buildModeHeroCard(
                context,
                title: 'Gọi thoại trực tiếp (Realtime Call)',
                subtitle: 'Cuộc gọi 2 chiều tự nhiên như người thật. Hỗ trợ ngắt lời và phản xạ tức thì.',
                duration: '5-15 phút',
                tag: 'Tăng phản xạ tự nhiên',
                icon: Icons.phone_in_talk_rounded,
                accentColor: const Color(0xFF9333EA),
                onTap: () => context.push('/practice/realtime/quick_call'),
              ),

              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadinessBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.mic, size: 16, color: AppColors.success),
          SizedBox(width: 6),
          Text(
            'Micro: Sẵn sàng',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
          Spacer(),
          Icon(Icons.wifi, size: 16, color: AppColors.success),
          SizedBox(width: 6),
          Text(
            'Mạng: Tốt (<80ms)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildModeHeroCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String duration,
    required String tag,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Bắt đầu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: accentColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
