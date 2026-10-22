import '../../../core/widgets/adaptive_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Screen 04 — Goal & Personalization Onboarding
/// Compliant with ESP-PLAN-001 Appendix B6 (Stepper 1/2)
class GoalOnboardingScreen extends ConsumerStatefulWidget {
  const GoalOnboardingScreen({super.key});

  @override
  ConsumerState<GoalOnboardingScreen> createState() =>
      _GoalOnboardingScreenState();
}

class _GoalOnboardingScreenState extends ConsumerState<GoalOnboardingScreen> {
  final Set<String> _selectedGoals = {'daily', 'work'};
  int _selectedMinutes = 15;
  String _selectedVoice = 'en-US-Journey-F';
  String _feedbackLanguage = 'vi'; // 'vi' or 'en'
  final Set<String> _selectedTopics = {'Đời sống', 'Du lịch', 'Công việc'};

  final List<Map<String, dynamic>> _goalsList = [
    {
      'id': 'daily',
      'title': 'Giao tiếp hàng ngày',
      'desc': 'Trò chuyện tự nhiên, phản xạ mượt mà không bị ngắc ngứ.',
      'icon': Icons.chat_bubble_outline_rounded,
      'color': AppColors.primary,
    },
    {
      'id': 'work',
      'title': 'Công việc & Họp hành',
      'desc': 'Thuyết trình, trao đổi với đồng nghiệp quốc tế & phỏng vấn.',
      'icon': Icons.work_outline_rounded,
      'color': AppColors.accent,
    },
    {
      'id': 'travel',
      'title': 'Du lịch nước ngoài',
      'desc': 'Hỏi đường, check-in khách sạn, gọi món nhà hàng tự tin.',
      'icon': Icons.flight_takeoff_rounded,
      'color': const Color(0xFF0284C7),
    },
    {
      'id': 'ielts',
      'title': 'Luyện thi IELTS Speaking',
      'desc': 'Cải thiện 4 tiêu chí Fluency, Lexical, Grammar & Pronunciation.',
      'icon': Icons.school_outlined,
      'color': const Color(0xFF9333EA),
    },
    {
      'id': 'interview',
      'title': 'Phỏng vấn xin việc',
      'desc': 'Tự giới thiệu bản thân, trả lời tình huống xử lý chuyên nghiệp.',
      'icon': Icons.badge_outlined,
      'color': AppColors.warning,
    },
  ];

  final List<String> _topicsList = [
    'Đời sống',
    'Du lịch',
    'Công việc',
    'Ẩm thực',
    'Công nghệ',
    'Phim ảnh',
    'Âm nhạc',
    'Kinh doanh',
    'Sức khỏe',
  ];

  Future<void> _saveAndContinue() async {
    await ref.read(authControllerProvider.notifier).completeOnboarding(
          goals: _selectedGoals.toList(),
          dailyMinutes: _selectedMinutes,
          topicInterests: _selectedTopics.toList(),
          preferredVoice: _selectedVoice,
          feedbackLanguage: _feedbackLanguage,
        );

    if (mounted) {
      context.push('/onboarding/placement');
    }
  }

  void _skipOnboarding() {
    _saveAndContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mục tiêu học (Bước 1/2)'),
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: const Text('Để sau',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar Stepper (1/2)
            const LinearProgressIndicator(
              value: 0.5,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.pageVertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Prompt Header
                    const Text(
                      'Bạn muốn tập trung vào điều gì?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tom Coach sẽ ưu tiên tạo kịch bản và phản hồi dựa trên mục tiêu này.',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Multi-select Goal Cards
                    ..._goalsList.map((g) {
                      final isSelected = _selectedGoals.contains(g['id']);
                      final Color cardColor = g['color'] as Color;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color: isSelected ? cardColor : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: cardColor.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  if (_selectedGoals.length > 1) {
                                    _selectedGoals.remove(g['id']);
                                  }
                                } else {
                                  _selectedGoals.add(g['id'] as String);
                                }
                              });
                            },
                            borderRadius: AppRadius.cardRadius,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: cardColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(g['icon'] as IconData,
                                        color: cardColor, size: 24),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          g['desc'] as String,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: cardColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedGoals.add(g['id'] as String);
                                        } else if (_selectedGoals.length > 1) {
                                          _selectedGoals.remove(g['id']);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: AppSpacing.lg),

                    // Section: Daily Practice Minutes
                    const Text(
                      'Thời gian bạn có thể dành ra mỗi ngày:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Duy trì đều đặn 15 phút mỗi ngày mang lại hiệu quả cao hơn học dồn cuối tuần.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      children: [
                        _buildMinuteOption(5, '5 phút', 'Duy trì phản xạ'),
                        const SizedBox(width: 8),
                        _buildMinuteOption(10, '10 phút', 'Tiến bộ ổn định'),
                        const SizedBox(width: 8),
                        _buildMinuteOption(15, '15 phút', 'Khuyên dùng'),
                        const SizedBox(width: 8),
                        _buildMinuteOption(20, '20 phút', 'Bứt phá nhanh'),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Section: Topic Interests
                    const Text(
                      'Chủ đề bạn yêu thích:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _topicsList.map((topic) {
                        final isSelected = _selectedTopics.contains(topic);
                        return FilterChip(
                          label: Text(topic),
                          selected: isSelected,
                          selectedColor: AppColors.secondaryLight,
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedTopics.add(topic);
                              } else {
                                _selectedTopics.remove(topic);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Section: Preferred Tom Coach Voice
                    const Text(
                      'Giọng gia sư Tom ưa thích:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: _buildVoiceCard(
                            id: 'en-US-Journey-F',
                            name: '🇺🇸 Tom',
                            accent: 'Anh - Mỹ (Nữ)',
                            desc: 'Ấm áp, tự nhiên & truyền cảm',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildVoiceCard(
                            id: 'en-GB-Journey-M',
                            name: '🇬🇧 Arthur',
                            accent: 'Anh - Anh (Nam)',
                            desc: 'Rõ ràng, đĩnh đạc & thanh lịch',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Section: Feedback Language
                    const Text(
                      'Ngôn ngữ giải thích lỗi sai:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RadioGroup<String>(
                      groupValue: _feedbackLanguage,
                      onChanged: (value) =>
                          setState(() => _feedbackLanguage = value ?? 'vi'),
                      child: const Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Tiếng Việt (Khuyến nghị)',
                                  style: TextStyle(fontSize: 14)),
                              value: 'vi',
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('English (100%)',
                                  style: TextStyle(fontSize: 14)),
                              value: 'en',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Proceed Action
            Container(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                text: 'Tiếp tục sang định vị trình độ',
                icon: Icons.arrow_forward_rounded,
                onPressed: _saveAndContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinuteOption(int mins, String label, String badge) {
    final isSelected = _selectedMinutes == mins;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMinutes = mins),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                badge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceCard({
    required String id,
    required String name,
    required String accent,
    required String desc,
  }) {
    final isSelected = _selectedVoice == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedVoice = id),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryLight : AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptiveRow(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 18),
              ],
            ),
            const SizedBox(height: 2),
            Text(accent,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
