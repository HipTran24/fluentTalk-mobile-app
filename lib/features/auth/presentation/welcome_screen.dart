import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/voice_waveform.dart';

/// Screen 02 — Welcome / Introduction
/// Compliant with ESP-PLAN-001 Appendix B4
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Luyện nói thực tế mỗi ngày',
      'subtitle': 'Không còn sợ sai hay thiếu người luyện tập cùng',
      'description':
          'Trò chuyện 1-1 cùng gia sư AI thông minh qua hàng chục kịch bản đời sống, du lịch, công việc và phỏng vấn xin việc.',
      'badge': 'Phản xạ tự nhiên',
      'icon': Icons.record_voice_over_rounded,
      'accent': AppColors.primary,
    },
    {
      'title': 'Nhận phản hồi & Sửa lỗi tức thì',
      'subtitle': 'Học từ chính lỗi sai của bạn theo ngữ cảnh',
      'description':
          'AI chỉ ra điểm chưa tự nhiên về ngữ pháp, phát âm và từ vựng ngay sau lượt nói, kèm bài tập sửa lỗi 3 phút cá nhân hóa.',
      'badge': 'Sửa lỗi chuyên sâu',
      'icon': Icons.auto_awesome_rounded,
      'accent': AppColors.accent,
    },
    {
      'title': 'Theo dõi tiến trình tăng trưởng',
      'subtitle': 'Đánh giá 4 tiêu chí chuẩn phản xạ giao tiếp',
      'description':
          'Xem báo cáo chi tiết về độ trôi chảy (Fluency), vốn từ (Lexical), ngữ pháp (Grammar) và phát âm (Pronunciation) sau mỗi buổi học.',
      'badge': 'Chuẩn IELTS-inspired',
      'icon': Icons.insights_rounded,
      'accent': const Color(0xFF9333EA),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    context.push('/auth?mode=signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FluentTalk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle Carousel Section
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final Color accentColor = slide['accent'] as Color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Abstract Visual Illustration Card
                        Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.cardRadiusLarge,
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Decorative Background Circles
                              Positioned(
                                top: -20,
                                right: -20,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accentColor.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -30,
                                left: -20,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.secondaryLight,
                                  ),
                                ),
                              ),
                              // Core Illustration Icon & Waveform
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accentColor.withOpacity(0.12),
                                    ),
                                    child: Icon(
                                      slide['icon'] as IconData,
                                      size: 52,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  VoiceWaveform(
                                    isActive: true,
                                    color: accentColor,
                                    height: 36,
                                    barCount: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.round),
                          ),
                          child: Text(
                            slide['badge'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Slide Title
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Description
                        Text(
                          slide['description'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (idx) {
                final isSelected = _currentPage == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Sticky Bottom CTAs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
              child: Column(
                children: [
                  PrimaryButton(
                    text: 'Bắt đầu ngay',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push('/auth?mode=signup'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SecondaryButton(
                    text: 'Tôi đã có tài khoản',
                    onPressed: () => context.push('/auth?mode=signin'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Dữ liệu âm thanh của bạn được bảo mật tuyệt đối theo chính sách bảo vệ quyền riêng tư.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
