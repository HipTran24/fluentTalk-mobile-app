import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/voice_waveform.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../domain/models/placement_models.dart';
import 'controllers/placement_controller.dart';

/// Screen 05 — Level Placement
/// Compliant with ESP-PLAN-001 Appendix A2, B7 (Stepper 2/2)
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  final TextEditingController _transcriptController = TextEditingController();

  @override
  void dispose() {
    _transcriptController.dispose();
    super.dispose();
  }

  void _finishPlacement(UserLevel level) {
    final authController = ref.read(authControllerProvider.notifier);
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(level: level);
      authController.completeOnboarding(
        goals: [updatedUser.goal.name],
        dailyMinutes: updatedUser.dailyMinutes,
        topicInterests: [],
        preferredVoice: 'en-US-Journey-F',
        feedbackLanguage: 'vi',
      );
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementControllerProvider);
    final questions = ref.watch(placementQuestionsProvider);
    final controller = ref.read(placementControllerProvider.notifier);

    final isResultStep = state.currentStep >= questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isResultStep ? 'Kết quả định vị' : 'Kiểm tra trình độ'),
        actions: [
          if (!isResultStep)
            TextButton(
              onPressed: () => _finishPlacement(UserLevel.a1),
              child: const Text('Bỏ qua', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Progress Indicator (2/2)
            LinearProgressIndicator(
              value: isResultStep ? 1.0 : 0.5 + (state.currentStep / (questions.length * 2)),
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),

            // Mode Selector Segmented Control (Only shown during test, hidden at results)
            if (!isResultStep)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => controller.toggleManualMode(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: !state.isManualMode ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !state.isManualMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mic,
                                  size: 16,
                                  color: !state.isManualMode ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Nói thử nghiệm',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: !state.isManualMode ? FontWeight.w700 : FontWeight.w500,
                                      color: !state.isManualMode ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => controller.toggleManualMode(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: state.isManualMode ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: state.isManualMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 16,
                                  color: state.isManualMode ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Tự chọn A0–C2',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: state.isManualMode ? FontWeight.w700 : FontWeight.w500,
                                      color: state.isManualMode ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Content Area
            Expanded(
              child: isResultStep
                  ? _buildResultView(state, controller)
                  : (state.isManualMode
                      ? _buildManualLevelSelection(state, controller)
                      : _buildInteractiveSpeakingTest(state, questions, controller)),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUBVIEW 1: INTERACTIVE SPEAKING TEST (3 Questions) ---
  Widget _buildInteractiveSpeakingTest(
    PlacementState state,
    List<dynamic> questions,
    PlacementController controller,
  ) {
    if (state.isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            SizedBox(height: AppSpacing.md),
            Text(
              'AI đang phân tích phản xạ và cấu trúc câu...',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'Đánh giá độ trôi chảy và vốn từ theo tiêu chuẩn',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final question = questions[state.currentStep];
    final answer = state.answers[question.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu hỏi ${state.currentStep + 1}/${questions.length}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              LevelChip(level: question.targetLevel),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question.promptVi,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),

          // English Prompt Card
          Container(
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
                    Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Prompt tiếng Anh:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"${question.promptEn}"',
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (question.sampleKeyPhrases as List<String>).map((phrase) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.round),
                      ),
                      child: Text(
                        phrase,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // User Response Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: state.isRecording ? AppColors.primary : AppColors.border,
                width: state.isRecording ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.record_voice_over_outlined, color: AppColors.accent, size: 18),
                    SizedBox(width: 6),
                    Text('Bản ghi nhận diện:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  state.isRecording
                      ? 'Đang lắng nghe câu trả lời của bạn...'
                      : (answer?.transcript ?? 'Chạm nút Micro bên dưới và nói câu trả lời của bạn bằng tiếng Anh.'),
                  style: TextStyle(
                    fontSize: 14,
                    color: state.isRecording
                        ? AppColors.primary
                        : (answer != null ? AppColors.textPrimary : AppColors.textMuted),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Waveform Display
          VoiceWaveform(
            isActive: state.isRecording,
            color: AppColors.primary,
            height: 48,
          ),

          const SizedBox(height: AppSpacing.md),

          // Large Recording Mic Button
          Center(
            child: GestureDetector(
              onTap: () {
                if (state.isRecording) {
                  controller.setRecording(false);
                  // Simulate transcript based on question
                  final sampleText = state.currentStep == 0
                      ? 'Hello, my name is Nam. I live in Da Nang and I really love reading books.'
                      : (state.currentStep == 1
                          ? 'On weekends, I usually go cycling with my friends because it makes me feel healthy.'
                          : 'I think practicing with an AI app is very flexible, but learners must stay disciplined.');
                  controller.submitAnswer(question.id, sampleText);
                } else {
                  controller.setRecording(true);
                }
              },
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isRecording ? AppColors.error : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (state.isRecording ? AppColors.error : AppColors.primary).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  state.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
          Center(
            child: Text(
              state.isRecording ? 'Chạm để dừng và hoàn thành' : 'Chạm để nói câu trả lời',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Navigation buttons (Previous / Next)
          Row(
            children: [
              if (state.currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.previousStep,
                    child: const Text('Câu trước'),
                  ),
                ),
              if (state.currentStep > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: state.currentStep < questions.length - 1 ? 'Tiếp tục câu sau' : 'Hoàn thành & Xem kết quả',
                  onPressed: () {
                    // Auto submit if not answered yet
                    if (answer == null) {
                      controller.submitAnswer(question.id, 'I am practicing my speaking skill.');
                    }
                    controller.nextStep();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SUBVIEW 2: MANUAL LEVEL SELECTION (A0 - C2) ---
  Widget _buildManualLevelSelection(PlacementState state, PlacementController controller) {
    final levels = [
      UserLevel.a0,
      UserLevel.a1,
      UserLevel.a2,
      UserLevel.b1,
      UserLevel.b2,
      UserLevel.c1,
      UserLevel.c2,
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn trình độ bạn cảm thấy phù hợp nhất',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bạn luôn có thể luyện tập các kịch bản vượt cấp độ mà không bị khóa tính năng.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              itemCount: levels.length,
              itemBuilder: (ctx, idx) {
                final lvl = levels[idx];
                final isSelected = state.selectedManualLevel == lvl;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      onTap: () => controller.selectManualLevel(lvl),
                      leading: LevelChip(level: lvl),
                      title: Text(
                        lvl.label,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    subtitle: Text(
                      lvl.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Radio<UserLevel>(
                      value: lvl,
                      groupValue: state.selectedManualLevel,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        if (val != null) controller.selectManualLevel(val);
                      },
                    ),
                  ),
                ),
              );
              },
            ),
          ),
          PrimaryButton(
            text: 'Bắt đầu với trình độ ${state.selectedManualLevel.code} (${state.selectedManualLevel.label})',
            onPressed: () => _finishPlacement(state.selectedManualLevel),
          ),
        ],
      ),
    );
  }

  // --- SUBVIEW 3: PLACEMENT RESULT VIEW ---
  Widget _buildResultView(PlacementState state, PlacementController controller) {
    final result = state.result ??
        const PlacementResult(
          estimatedLevel: UserLevel.a2,
          confidence: 0.85,
          evaluationSummary: 'Bạn có phản xạ giao tiếp cơ bản tốt trong các tình huống hàng ngày.',
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardRadiusLarge,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 6),
                const Text(
                  'Trình độ phản xạ đề xuất của bạn',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                LevelChip(level: result.estimatedLevel),
                const SizedBox(height: 10),
                Text(
                  'Level ${result.estimatedLevel.code} — ${result.estimatedLevel.label}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                  child: Text(
                    'Độ tin cậy đánh giá: ${(result.confidence * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  result.evaluationSummary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Strengths & Focus Areas
          if (result.identifiedStrengths.isNotEmpty) ...[
            Container(
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
                      Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('Ưu điểm nhận diện được:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...result.identifiedStrengths.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $s', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Educational Disclaimer (AGENT-16)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.disclaimer,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.35),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // CTA: Bắt đầu học
          PrimaryButton(
            text: 'Vào học ngay với Level ${result.estimatedLevel.code}',
            icon: Icons.rocket_launch_rounded,
            onPressed: () => _finishPlacement(result.estimatedLevel),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: controller.resetTest,
            child: const Text('Làm lại bài kiểm tra'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
