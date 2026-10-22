import '../../../core/widgets/adaptive_row.dart';
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
                title: 'Hỏi bằng Text, Nghe Tom nói',
                subtitle:
                    'Gõ câu hỏi tiếng Anh hoặc Việt, Tom sẽ phát âm phản hồi tự nhiên.',
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
                subtitle:
                    'Hội thoại nhập vai từng câu với Tom. Xem transcript và nhận gợi ý tức thì.',
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
                subtitle:
                    'Cuộc gọi 2 chiều tự nhiên như người thật. Hỗ trợ ngắt lời và phản xạ tức thì.',
                duration: '5-15 phút',
                tag: 'Tăng phản xạ tự nhiên',
                icon: Icons.phone_in_talk_rounded,
                accentColor: AppColors.purple,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.softShadow,
      ),
      child: AdaptiveRow(
        children: [
          _statusPill(Icons.mic_rounded, 'Micro: Sẵn sàng'),
          const Spacer(),
          _statusPill(Icons.wifi_rounded, 'Mạng: Tốt (<80ms)'),
        ],
      ),
    );
  }

  Widget _statusPill(IconData icon, String label) {
    return AdaptiveRow(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
              color: AppColors.successBg, shape: BoxShape.circle),
          child: Icon(icon, size: 13, color: AppColors.success),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }

  LinearGradient _gradientFor(Color c) {
    if (c == AppColors.accent) return AppColors.accentGradient;
    if (c == AppColors.primary) return AppColors.brandGradient;
    return AppColors.purpleGradient;
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
    final gradient = _gradientFor(accentColor);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadiusLarge,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.glow(accentColor, opacity: 0.3),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.round),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                AdaptiveRow(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AdaptiveRow(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 15, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(AppRadius.round),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Bắt đầu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 15, color: Colors.white),
                        ],
                      ),
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
