import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_logo.dart';
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
      'gradient': AppColors.brandGradientVivid,
      'chips': ['☕ Gọi món', '✈️ Du lịch', '💼 Phỏng vấn'],
    },
    {
      'title': 'Nhận phản hồi & Sửa lỗi tức thì',
      'subtitle': 'Học từ chính lỗi sai của bạn theo ngữ cảnh',
      'description':
          'AI chỉ ra điểm chưa tự nhiên về ngữ pháp, phát âm và từ vựng ngay sau lượt nói, kèm bài tập sửa lỗi 3 phút cá nhân hóa.',
      'badge': 'Sửa lỗi chuyên sâu',
      'icon': Icons.auto_awesome_rounded,
      'accent': AppColors.accent,
      'gradient': AppColors.accentGradient,
      'chips': ['✅ Ngữ pháp', '🗣️ Phát âm', '📚 Từ vựng'],
    },
    {
      'title': 'Theo dõi tiến trình tăng trưởng',
      'subtitle': 'Đánh giá 4 tiêu chí chuẩn phản xạ giao tiếp',
      'description':
          'Xem báo cáo chi tiết về độ trôi chảy (Fluency), vốn từ (Lexical), ngữ pháp (Grammar) và phát âm (Pronunciation) sau mỗi buổi học.',
      'badge': 'Chuẩn IELTS-inspired',
      'icon': Icons.insights_rounded,
      'accent': AppColors.purple,
      'gradient': AppColors.purpleGradient,
      'chips': ['📈 Fluency', '🎯 Grammar', '🏆 Band 6.5+'],
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
    final Color activeAccent = _slides[_currentPage]['accent'] as Color;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.softBackdrop),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Brand & Skip button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppLogoWordmark(logoSize: 34, fontSize: 19, showAiBadge: true),
                    TextButton(
                      onPressed: _onSkip,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.round),
                        ),
                      ),
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
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
                  itemBuilder: (context, index) => _buildSlide(_slides[index]),
                ),
              ),

              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (idx) {
                  final isSelected = _currentPage == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? activeAccent : AppColors.divider.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.xl),

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
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      text: 'Tôi đã có tài khoản',
                      onPressed: () => context.push('/auth?mode=signin'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textMuted),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Dữ liệu âm thanh của bạn được bảo mật tuyệt đối theo chính sách bảo vệ quyền riêng tư.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    final Color accentColor = slide['accent'] as Color;
    final LinearGradient gradient = slide['gradient'] as LinearGradient;
    final List<String> chips = (slide['chips'] as List).cast<String>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = (constraints.maxHeight * 0.48).clamp(180.0, 260.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gradient Illustration Card
                Container(
                  width: double.infinity,
                  height: illustrationHeight,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppColors.glow(accentColor, opacity: 0.28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative rings
                        Positioned(top: -50, right: -40, child: _ring(170)),
                        Positioned(bottom: -70, left: -50, child: _ring(200)),
                        // Floating topic chips
                        Positioned(top: 18, left: 16, child: _floatingChip(chips[0])),
                        Positioned(top: 52, right: 16, child: _floatingChip(chips[1])),
                        Positioned(bottom: 18, left: 28, child: _floatingChip(chips[2])),
                        // Core illustration
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (b) => gradient.createShader(b),
                                child: Icon(slide['icon'] as IconData, size: 44, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const VoiceWaveform(
                              isActive: true,
                              color: Colors.white,
                              height: 30,
                              barCount: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Badge Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.round),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
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
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  slide['subtitle'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Description
                Text(
                  slide['description'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ring(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
    );
  }

  Widget _floatingChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.round),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
