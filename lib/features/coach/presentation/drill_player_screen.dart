import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/voice_waveform.dart';
import 'controllers/coach_controller.dart';

/// Screen 17 — Corrective Drill Player
/// Compliant with ESP-PLAN-001 Appendix B19
class DrillPlayerScreen extends ConsumerWidget {
  final String drillId;

  const DrillPlayerScreen({
    super.key,
    required this.drillId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drillPlayerControllerProvider(drillId));
    final controller =
        ref.read(drillPlayerControllerProvider(drillId).notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.isCompleted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Hoàn thành bài tập')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 48)),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Tuyệt vời! Bạn đã hoàn thành Drill 3 phút!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Điểm phản xạ trung bình: 95/100. Điểm yếu ngữ pháp đã được cải thiện.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  text: 'Quay lại Trợ lý Tom',
                  icon: Icons.check_circle_rounded,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final drill = state.drill;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text('Bài tập sửa lỗi (${state.currentStep}/${state.totalSteps})'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.currentStep / state.totalSteps,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Mục tiêu: ${drill?.objective ?? "Luyện phản xạ chuẩn xác"}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nghe và nói lại câu chuẩn bản xứ:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),

              // Target Sentence Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '"${drill?.targetPhrase ?? "Yesterday, I went to the supermarket."}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Đang phát âm thanh mẫu chuẩn bản xứ...'),
                              duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                      label: const Text('Nghe mẫu chuẩn bản xứ'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Instant Result Card
              if (state.hasResult) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Chính xác xuất sắc!',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.success),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${state.score.toInt()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bạn đã nói: "${state.spokenTranscript}"',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  text: state.currentStep < state.totalSteps
                      ? 'Bước tiếp theo'
                      : 'Hoàn thành bài tập',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: controller.nextStep,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Waveform Display
              Center(
                child: VoiceWaveform(
                  isActive: state.isRecording,
                  color: AppColors.primary,
                  height: 48,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Mic Button
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (state.isRecording) {
                      controller.stopRecording();
                    } else {
                      controller.startRecording();
                    }
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isRecording
                          ? AppColors.error
                          : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (state.isRecording
                                  ? AppColors.error
                                  : AppColors.primary)
                              .withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      state.isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  state.isRecording
                      ? 'Chạm để dừng và chấm điểm'
                      : 'Chạm vào Micro để đọc câu',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
