import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheets/confirm_sheet.dart';
import '../../../core/widgets/voice_waveform.dart';
import '../domain/models/guided_models.dart';
import 'controllers/guided_controller.dart';

/// Screen 11 — Mode 2: Guided Speaking Session
/// Compliant with ESP-PLAN-001 Appendix B11 & MODE-02
class GuidedSpeakingScreen extends ConsumerStatefulWidget {
  final String scenarioId;

  const GuidedSpeakingScreen({
    super.key,
    required this.scenarioId,
  });

  @override
  ConsumerState<GuidedSpeakingScreen> createState() => _GuidedSpeakingScreenState();
}

class _GuidedSpeakingScreenState extends ConsumerState<GuidedSpeakingScreen> {
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _showEditTranscriptDialog(String currentText, GuidedSpeakingController controller) {
    _editController.text = currentText;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: const Text(
          'Chỉnh sửa câu trả lời',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: _editController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Nhập lại nội dung câu nói của bạn...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateTranscriptDraft(_editController.text);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guidedSpeakingControllerProvider(widget.scenarioId));
    final controller = ref.read(guidedSpeakingControllerProvider(widget.scenarioId).notifier);

    // If session is completed, navigate to summary
    ref.listen<GuidedSpeakingState>(
      guidedSpeakingControllerProvider(widget.scenarioId),
      (previous, next) {
        if (next.isCompleted && previous?.isCompleted != true) {
          context.pushReplacement('/practice/session/${next.sessionId}/summary');
        }
      },
    );

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: AppSpacing.md),
              Text(
                'Đang chuẩn bị phiên luyện nói...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final currentTurn = state.currentTurn;
    if (currentTurn == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Lỗi tải kịch bản')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(state.errorMessage ?? 'Không tìm thấy dữ liệu lượt nói.'),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Quay lại',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await ConfirmSheet.show(
          context,
          title: 'Dừng phiên luyện nói?',
          message: 'Tiến trình lượt nói hiện tại sẽ được lưu lại để bạn có thể tiếp tục bất kỳ lúc nào.',
          confirmText: 'Dừng phiên',
          cancelText: 'Tiếp tục luyện',
        );
        if (context.mounted && confirmed == true) {
          context.pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () async {
            final confirmed = await ConfirmSheet.show(
              context,
              title: 'Dừng phiên luyện nói?',
              message: 'Tiến trình lượt nói hiện tại sẽ được lưu lại để bạn có thể tiếp tục bất kỳ lúc nào.',
              confirmText: 'Dừng phiên',
              cancelText: 'Tiếp tục luyện',
            );
            if (context.mounted && confirmed == true) {
              context.pop();
            }
          },
        ),
        title: Column(
          children: [
            Text(
              'Lượt ${state.currentTurnIndex + 1}/${state.totalTurns}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                width: 100,
                height: 4,
                child: LinearProgressIndicator(
                  value: state.progressPercentage,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Audio Speed Selector (0.75x, 1.0x, 1.25x)
          PopupMenuButton<double>(
            initialValue: state.aiSpeechRate,
            tooltip: 'Tốc độ giọng đọc AI',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.aiSpeechRate}x',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            onSelected: controller.setAiSpeechRate,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.75, child: Text('0.75x (Chậm - Dành cho người mới)')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x (Chuẩn bản xứ)')),
              const PopupMenuItem(value: 1.25, child: Text('1.25x (Nhanh - Nâng cao)')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Roles & Context Bar
                    _buildRoleContextBar(currentTurn),

                    const SizedBox(height: AppSpacing.md),

                    // 2. AI Question / Spoken Prompt Card
                    _buildAiPromptCard(context, state, currentTurn, controller),

                    const SizedBox(height: AppSpacing.md),

                    // 3. Reflex Objective & Starters
                    _buildUserGoalCard(currentTurn, controller),

                    const SizedBox(height: AppSpacing.md),

                    // 4. Instant Turn Feedback (If evaluated)
                    if (state.latestFeedback != null)
                      _buildTurnFeedbackCard(context, state.latestFeedback!, controller, state),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // 5. Speaking Stage / Bottom Recording Controls
            _buildRecordingStage(context, state, controller),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildRoleContextBar(GuidedTurn turn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'AI: ${turn.aiRole}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Icon(Icons.sync_alt_rounded, size: 16, color: AppColors.textMuted),
          Row(
            children: [
              const Icon(Icons.person_pin_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                'Bạn: ${turn.userRole}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiPromptCard(
    BuildContext context,
    GuidedSpeakingState state,
    GuidedTurn turn,
    GuidedSpeakingController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: state.isAiSpeaking ? AppColors.primary : AppColors.border,
          width: state.isAiSpeaking ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: state.isAiSpeaking ? AppColors.primary.withOpacity(0.08) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: state.isAiSpeaking ? AppColors.primary : AppColors.secondaryLight,
                child: Icon(
                  state.isAiSpeaking ? Icons.volume_up_rounded : Icons.psychology,
                  color: state.isAiSpeaking ? Colors.white : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      turn.aiRole,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      state.isAiSpeaking ? 'Đang phát âm thanh...' : 'Chạm loa để nghe lại',
                      style: TextStyle(
                        fontSize: 11,
                        color: state.isAiSpeaking ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  state.isAiSpeaking ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                onPressed: controller.toggleAiSpeaking,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Spoken English text
          Text(
            '"${turn.aiPromptEn}"',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),

          // Optional Translation & IPA View
          if (state.showAiTranslation) ...[
            const SizedBox(height: AppSpacing.sm),
            if (turn.aiPromptIpa != null)
              Text(
                turn.aiPromptIpa!,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.accent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Dịch: "${turn.aiPromptVi}"',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xs),

          // Translation toggle button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller.toggleTranslation,
              icon: Icon(
                state.showAiTranslation ? Icons.visibility_off_outlined : Icons.translate_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              label: Text(
                state.showAiTranslation ? 'Ẩn bản dịch & IPA' : 'Xem dịch & phiên âm',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGoalCard(GuidedTurn turn, GuidedSpeakingController controller) {
    return Container(
      width: double.infinity,
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
              Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Mục tiêu lượt nói của bạn:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            turn.userGoalVi,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          if (turn.suggestedStarters.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Gợi ý mở đầu câu:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: turn.suggestedStarters.map((starter) {
                return ActionChip(
                  label: Text(
                    starter,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                  backgroundColor: AppColors.secondaryLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide.none,
                  onPressed: () {
                    controller.updateTranscriptDraft(starter);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTurnFeedbackCard(
    BuildContext context,
    TurnFeedback feedback,
    GuidedSpeakingController controller,
    GuidedSpeakingState state,
  ) {
    final isLastTurn = state.currentTurnIndex + 1 >= state.totalTurns;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Mint Green background
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Đánh giá lượt nói',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.success),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${feedback.score.toInt()} / 100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            feedback.praise,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35),
          ),
          if (feedback.nativeAlternative != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'Cách nói bản xứ tự nhiên hơn:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    feedback.nativeAlternative!,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            text: isLastTurn ? 'Xem tổng kết phiên (Report)' : 'Sang lượt tiếp theo',
            icon: isLastTurn ? Icons.assessment_rounded : Icons.arrow_forward_rounded,
            onPressed: controller.nextTurn,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingStage(
    BuildContext context,
    GuidedSpeakingState state,
    GuidedSpeakingController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // STAGE A: TRANSCRIPT REVIEW
          if (state.recordingState == RecordingState.reviewing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mic_none_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Câu nói nhận diện được:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showEditTranscriptDialog(state.currentTranscriptDraft, controller),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '"${state.currentTranscriptDraft}"',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.recordAgain,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Nói lại'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: controller.submitTurn,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Gửi & Đánh giá'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ]
          // STAGE B: TRANSCRIBING STT
          else if (state.recordingState == RecordingState.transcribing ||
              state.recordingState == RecordingState.evaluating) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'AI đang chuyển giọng nói thành văn bản...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ]
          // STAGE C: RECORDING OR IDLE
          else ...[
            if (state.recordingState == RecordingState.recording) ...[
              // Live Timer & Waveform
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '00:${state.recordingDurationSeconds.toString().padLeft(2, '0')} / 00:45',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const VoiceWaveform(
                isActive: true,
                color: AppColors.error,
                height: 40,
                barCount: 22,
              ),
              const SizedBox(height: 10),
            ],

            // Microphone Big Action Button
            GestureDetector(
              onTap: () {
                if (state.recordingState == RecordingState.recording) {
                  controller.stopRecording();
                } else {
                  controller.startRecording();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.recordingState == RecordingState.recording ? AppColors.error : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (state.recordingState == RecordingState.recording ? AppColors.error : AppColors.primary)
                          .withOpacity(0.35),
                      blurRadius: state.recordingState == RecordingState.recording ? 24 : 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  state.recordingState == RecordingState.recording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.recordingState == RecordingState.recording
                  ? 'Chạm nút đỏ để hoàn tất nói'
                  : 'Chạm vào Micro để bắt đầu nói',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],

          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
