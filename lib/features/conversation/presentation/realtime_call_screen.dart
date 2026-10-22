import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/sheets/confirm_sheet.dart';
import '../../../core/widgets/voice_waveform.dart';
import '../domain/models/realtime_models.dart';
import 'controllers/realtime_controller.dart';

/// Screen 12 — Mode 3: Realtime Voice Conversation
/// Compliant with ESP-PLAN-001 Appendix B14 & MODE-03
class RealtimeCallScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const RealtimeCallScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<RealtimeCallScreen> createState() => _RealtimeCallScreenState();
}

class _RealtimeCallScreenState extends ConsumerState<RealtimeCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _showTopicHintsSheet(BuildContext context, List<ConversationTopicHint> hints, RealtimeCallController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B), // Dark slate
          borderRadius: AppRadius.sheetRadius,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Gợi ý chủ đề trò chuyện',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Chạm vào một câu để nói trực tiếp với AI nếu bạn đang bí ý tưởng:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              ...hints.map((hint) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        title: Text(
                          hint.englishPhrase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '(${hint.vietnameseMeaning})',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                        onTap: () {
                          controller.simulateUserSpeech(hint.englishPhrase);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  )),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _showTranscriptHistorySheet(BuildContext context, List<RealtimeCaptionItem> history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: AppRadius.sheetRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Lịch sử cuộc gọi',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = history[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: item.isAi ? AppColors.primaryLight : AppColors.userWaveform,
                          child: Icon(
                            item.isAi ? Icons.psychology : Icons.person,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.isAi ? 'Coach Emma' : 'Bạn',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: item.isAi ? AppColors.primaryLight : AppColors.userWaveform,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.text,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(realtimeCallControllerProvider(widget.sessionId));
    final controller = ref.read(realtimeCallControllerProvider(widget.sessionId).notifier);

    // When call ends, transition to summary
    ref.listen<RealtimeCallState>(
      realtimeCallControllerProvider(widget.sessionId),
      (previous, next) {
        if (next.isCallEnded && previous?.isCallEnded != true) {
          context.pushReplacement('/practice/session/${widget.sessionId}/summary');
        }
      },
    );

    final isAiSpeaking = state.speakerState == RealtimeSpeakerState.aiSpeaking;
    final isUserSpeaking = state.speakerState == RealtimeSpeakerState.userSpeaking;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await ConfirmSheet.show(
          context,
          title: 'Kết thúc cuộc gọi?',
          message: 'Hệ thống sẽ dừng ghi âm và tạo báo cáo đánh giá toàn diện (Rubric) cho phiên nói của bạn.',
          confirmText: 'Kết thúc & Nhận điểm',
          cancelText: 'Tiếp tục gọi',
          isDestructive: true,
        );
        if (context.mounted && confirmed == true) {
          controller.endCall();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.callSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              // 1. TOP HEADER: Status, Timer, Latency & Topic hints
              _buildTopBar(context, state, controller),

              // 2. CENTER STAGE (Pinned between Top and Bottom Controls)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        // 2. Ripple Rings & Coach Emma Avatar (Isolated GPU RepaintBoundary)
                        RepaintBoundary(
                          child: _buildCenterAvatar(state, controller, isAiSpeaking, isUserSpeaking),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 3. SPEAKER STATUS BADGE / BARGE-IN BUTTON
                        _buildSpeakerStatusBadge(state, controller),

                        const SizedBox(height: AppSpacing.md),

                        // 4. DUAL WAVEFORM VISUALIZER (Isolated GPU RepaintBoundary)
                        RepaintBoundary(
                          child: _buildWaveformVisualizer(state, isAiSpeaking, isUserSpeaking),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 5. LIVE CAPTIONS & SUBTITLES BOX
                        if (state.showCaptions) _buildLiveCaptionsBox(context, state),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. BOTTOM CALL ACTION CONTROLS (Always accessible)
              _buildCallControls(context, state, controller),

              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildTopBar(
    BuildContext context,
    RealtimeCallState state,
    RealtimeCallController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Live status & latency
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.round),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Trực tiếp',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${state.latencyMs}ms',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),

        // Monospaced Call Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.round),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            state.formattedDuration,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Topic Hints Button
        IconButton(
          tooltip: 'Gợi ý chủ đề khi bí ý tưởng',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentLight, size: 20),
          ),
          onPressed: () => _showTopicHintsSheet(context, state.topicHints, controller),
        ),
      ],
    );
  }

  Widget _buildCenterAvatar(
    RealtimeCallState state,
    RealtimeCallController controller,
    bool isAiSpeaking,
    bool isUserSpeaking,
  ) {
    final activeColor = isAiSpeaking
        ? AppColors.primaryLight
        : (isUserSpeaking ? AppColors.userWaveform : Colors.white24);

    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final rippleValue = (isAiSpeaking || isUserSpeaking) ? _rippleController.value : 0.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Concentric Glow Ring 2
            Container(
              width: 170 + (rippleValue * 30),
              height: 170 + (rippleValue * 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity((1 - rippleValue) * 0.15),
              ),
            ),
            // Outer Concentric Glow Ring 1
            Container(
              width: 140 + (rippleValue * 20),
              height: 140 + (rippleValue * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity((1 - rippleValue) * 0.25),
              ),
            ),
            // Center Circular Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                border: Border.all(color: activeColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.psychology, size: 62, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeakerStatusBadge(
    RealtimeCallState state,
    RealtimeCallController controller,
  ) {
    if (state.speakerState == RealtimeSpeakerState.aiSpeaking) {
      return GestureDetector(
        onTap: controller.interruptAi,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volume_up_rounded, color: AppColors.primaryLight, size: 16),
              SizedBox(width: 6),
              Text(
                'Coach Emma đang nói • Chạm để ngắt lời',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    } else if (state.speakerState == RealtimeSpeakerState.userSpeaking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentLight.withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_rounded, color: AppColors.accentLight, size: 16),
            SizedBox(width: 6),
            Text(
              'Đang thu âm giọng của bạn...',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    } else if (state.speakerState == RealtimeSpeakerState.aiThinking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
            SizedBox(width: 8),
            Text(
              'AI đang phản xạ câu trả lời...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'AI đang lắng nghe bạn nói...',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }
  }

  Widget _buildWaveformVisualizer(
    RealtimeCallState state,
    bool isAiSpeaking,
    bool isUserSpeaking,
  ) {
    return Column(
      children: [
        VoiceWaveform(
          isActive: isAiSpeaking || isUserSpeaking,
          color: isAiSpeaking
              ? AppColors.aiWaveform
              : (isUserSpeaking ? AppColors.userWaveform : Colors.white24),
          height: 48,
          barCount: 26,
        ),
        const SizedBox(height: 6),
        Text(
          isAiSpeaking ? 'Kênh phát AI (TTS)' : (isUserSpeaking ? 'Kênh nói của Bạn (Mic)' : 'Đang chờ giọng nói'),
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildLiveCaptionsBox(
    BuildContext context,
    RealtimeCallState state,
  ) {
    return GestureDetector(
      onTap: () => _showTranscriptHistorySheet(context, state.captionsHistory),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: state.currentSpeakerRole == 'ai' ? AppColors.primaryLight : AppColors.userWaveform,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.currentSpeakerRole == 'ai' ? 'Coach Emma' : 'Bạn',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: state.currentSpeakerRole == 'ai' ? AppColors.primaryLight : AppColors.userWaveform,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Icon(Icons.history_rounded, size: 14, color: Colors.white60),
                    SizedBox(width: 4),
                    Text(
                      'Lịch sử',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '"${state.currentSpeakerText}"',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls(
    BuildContext context,
    RealtimeCallState state,
    RealtimeCallController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 1. Mute Toggle
        IconButton.filledTonal(
          tooltip: state.isMuted ? 'Bật micro' : 'Tắt tiếng (Mute)',
          style: IconButton.styleFrom(
            backgroundColor: state.isMuted ? Colors.white30 : Colors.white12,
            padding: const EdgeInsets.all(16),
          ),
          icon: Icon(
            state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: state.isMuted ? AppColors.error : Colors.white,
            size: 26,
          ),
          onPressed: controller.toggleMute,
        ),

        // 2. Speakerphone Toggle
        IconButton.filledTonal(
          tooltip: state.isSpeakerPhoneOn ? 'Loa ngoài' : 'Tai nghe/Loa trong',
          style: IconButton.styleFrom(
            backgroundColor: state.isSpeakerPhoneOn ? Colors.white30 : Colors.white12,
            padding: const EdgeInsets.all(16),
          ),
          icon: Icon(
            state.isSpeakerPhoneOn ? Icons.volume_up_rounded : Icons.phone_in_talk_rounded,
            color: Colors.white,
            size: 26,
          ),
          onPressed: controller.toggleSpeakerPhone,
        ),

        // 3. Captions Toggle
        IconButton.filledTonal(
          tooltip: state.showCaptions ? 'Ẩn phụ đề' : 'Bật phụ đề trực tiếp',
          style: IconButton.styleFrom(
            backgroundColor: state.showCaptions ? Colors.white30 : Colors.white12,
            padding: const EdgeInsets.all(16),
          ),
          icon: Icon(
            state.showCaptions ? Icons.subtitles_rounded : Icons.subtitles_off_rounded,
            color: Colors.white,
            size: 26,
          ),
          onPressed: controller.toggleCaptions,
        ),

        // 4. End Call Button (Big Red)
        IconButton.filled(
          tooltip: 'Kết thúc cuộc gọi',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.all(20),
          ),
          icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
          onPressed: () async {
            final confirmed = await ConfirmSheet.show(
              context,
              title: 'Kết thúc cuộc gọi?',
              message: 'Hệ thống sẽ dừng ghi âm và tạo báo cáo đánh giá toàn diện (Rubric) cho phiên nói của bạn.',
              confirmText: 'Kết thúc & Nhận điểm',
              cancelText: 'Tiếp tục gọi',
              isDestructive: true,
            );
            if (context.mounted && confirmed == true) {
              controller.endCall();
            }
          },
        ),
      ],
    );
  }
}
