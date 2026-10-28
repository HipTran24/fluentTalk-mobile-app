import '../../../core/widgets/adaptive_row.dart';
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

class _RealtimeCallScreenState extends ConsumerState<RealtimeCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  bool _endingCall = false;

  Color _speakerColor(RealtimeSpeakerState speaker) {
    switch (speaker) {
      case RealtimeSpeakerState.aiSpeaking:
        return const Color(0xFFB6A8FF);
      case RealtimeSpeakerState.userSpeaking:
        return const Color(0xFF71E0C4);
      case RealtimeSpeakerState.aiThinking:
        return const Color(0xFFFFD18B);
      case RealtimeSpeakerState.connecting:
        return const Color(0xFF9ACBFF);
      case RealtimeSpeakerState.listening:
        return const Color(0xFFB5C5DA);
      case RealtimeSpeakerState.ended:
        return const Color(0xFFFFA3AE);
    }
  }

  Future<void> _confirmEndCall(RealtimeCallController controller) async {
    if (_endingCall) return;
    setState(() => _endingCall = true);
    try {
      final confirmed = await ConfirmSheet.show(
        context,
        title: 'Kết thúc cuộc gọi?',
        message: 'Bạn sẽ kết thúc phiên hiện tại và chuyển đến trang tổng kết.',
        confirmText: 'Kết thúc cuộc gọi',
        cancelText: 'Tiếp tục gọi',
        isDestructive: true,
      );
      if (!mounted || confirmed != true) return;
      await controller.endCall();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Chưa kết thúc được phiên. Vui lòng thử lại.')));
      }
    } finally {
      if (mounted) setState(() => _endingCall = false);
    }
  }

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

  void _showTopicHintsSheet(BuildContext context,
      List<ConversationTopicHint> hints, RealtimeCallController controller) {
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
                  Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.accentLight, size: 20),
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
                'Chạm vào một câu để nói trực tiếp với Tom nếu bạn đang bí ý tưởng:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              ...hints.map((hint) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
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
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white38, size: 14),
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

  void _showTranscriptHistorySheet(
      BuildContext context, List<RealtimeCaptionItem> history) {
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
                  Icon(Icons.history_rounded,
                      color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Lịch sử cuộc gọi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.forum_outlined,
                                      color: Colors.white54, size: 38),
                                  SizedBox(height: 12),
                                  Text('Chưa có hội thoại',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(height: 8),
                                  Text(
                                      'Nội dung hội thoại sẽ xuất hiện tại đây khi phiên bắt đầu.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white60, height: 1.5)),
                                ])))
                    : ListView.separated(
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
                                backgroundColor: item.isAi
                                    ? AppColors.primaryLight
                                    : AppColors.userWaveform,
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
                                      item.isAi ? 'Coach Tom' : 'Bạn',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: item.isAi
                                            ? AppColors.primaryLight
                                            : AppColors.userWaveform,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.text,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          height: 1.35),
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
    final controller =
        ref.read(realtimeCallControllerProvider(widget.sessionId).notifier);

    // When call ends, transition to summary
    ref.listen<RealtimeCallState>(
      realtimeCallControllerProvider(widget.sessionId),
      (previous, next) {
        if (next.isCallEnded && previous?.isCallEnded != true) {
          context
              .pushReplacement('/practice/session/${widget.sessionId}/summary');
        }
      },
    );

    final isAiSpeaking = state.speakerState == RealtimeSpeakerState.aiSpeaking;
    final isUserSpeaking =
        state.speakerState == RealtimeSpeakerState.userSpeaking;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmEndCall(controller);
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
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          // 2. Ripple Rings & Coach Tom Avatar (Isolated GPU RepaintBoundary)
                          RepaintBoundary(
                            child: _buildCenterAvatar(state, controller,
                                isAiSpeaking, isUserSpeaking),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // 3. SPEAKER STATUS BADGE / BARGE-IN BUTTON
                          _buildSpeakerStatusBadge(state, controller),

                          const SizedBox(height: AppSpacing.md),

                          // 4. DUAL WAVEFORM VISUALIZER (Isolated GPU RepaintBoundary)
                          RepaintBoundary(
                            child: _buildWaveformVisualizer(
                                state, isAiSpeaking, isUserSpeaking),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // 5. LIVE CAPTIONS & SUBTITLES BOX
                          if (state.showCaptions)
                            _buildLiveCaptionsBox(context, state),
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

  Widget _buildTopBar(BuildContext context, RealtimeCallState state,
      RealtimeCallController controller) {
    final color = _speakerColor(state.speakerState);
    final connecting = state.speakerState == RealtimeSpeakerState.connecting;
    final ended = state.speakerState == RealtimeSpeakerState.ended;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IconButton(
        tooltip: 'Quay lại · kết thúc cuộc gọi',
        onPressed: _endingCall ? null : () => _confirmEndCall(controller),
        icon: Icon(Icons.arrow_back_rounded,
            color: _endingCall ? Colors.white38 : Colors.white),
      ),
      const SizedBox(width: 4),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: color.withValues(alpha: 0.3))),
                    child: Text(
                        connecting
                            ? 'Đang kết nối'
                            : ended
                                ? 'Đã kết thúc'
                                : 'Cuộc gọi demo',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700))),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18)),
                    child: Text(state.formattedDuration,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace'))),
              ]))),
      IconButton(
          tooltip: 'Gợi ý chủ đề',
          onPressed: _endingCall
              ? null
              : () =>
                  _showTopicHintsSheet(context, state.topicHints, controller),
          icon: const Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFFFFD18B))),
    ]);
  }

  Widget _buildCenterAvatar(
    RealtimeCallState state,
    RealtimeCallController controller,
    bool isAiSpeaking,
    bool isUserSpeaking,
  ) {
    final activeColor = _speakerColor(state.speakerState);

    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final rippleValue =
            (isAiSpeaking || isUserSpeaking) ? _rippleController.value : 0.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Concentric Glow Ring 2
            Container(
              width: 170 + (rippleValue * 30),
              height: 170 + (rippleValue * 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: (1 - rippleValue) * 0.15),
              ),
            ),
            // Outer Concentric Glow Ring 1
            Container(
              width: 140 + (rippleValue * 20),
              height: 140 + (rippleValue * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: (1 - rippleValue) * 0.25),
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
                    color: activeColor.withValues(alpha: 0.4),
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
      RealtimeCallState state, RealtimeCallController controller) {
    final color = _speakerColor(state.speakerState);
    final speaking = state.speakerState == RealtimeSpeakerState.aiSpeaking;
    final busy = state.speakerState == RealtimeSpeakerState.connecting ||
        state.speakerState == RealtimeSpeakerState.aiThinking;
    late final String label;
    late final IconData icon;
    switch (state.speakerState) {
      case RealtimeSpeakerState.connecting:
        label = 'Đang thiết lập cuộc gọi…';
        icon = Icons.wifi_rounded;
        break;
      case RealtimeSpeakerState.aiSpeaking:
        label = 'Tom đang nói · Chạm để ngắt lời';
        icon = Icons.volume_up_rounded;
        break;
      case RealtimeSpeakerState.userSpeaking:
        label = state.isMuted ? 'Micro đang tắt' : 'Đến lượt bạn nói';
        icon = state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded;
        break;
      case RealtimeSpeakerState.aiThinking:
        label = 'Tom đang chuẩn bị câu trả lời…';
        icon = Icons.auto_awesome_rounded;
        break;
      case RealtimeSpeakerState.listening:
        label = state.isMuted ? 'Micro đang tắt' : 'Tom đang lắng nghe';
        icon = state.isMuted ? Icons.mic_off_rounded : Icons.hearing_rounded;
        break;
      case RealtimeSpeakerState.ended:
        label = 'Cuộc gọi đã kết thúc';
        icon = Icons.call_end_rounded;
        break;
    }
    return Semantics(
        liveRegion: true,
        child: Material(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: speaking && !_endingCall ? controller.interruptAi : null,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (busy)
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: color))
                  else
                    Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(label,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600))),
                ])),
          ),
        ));
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
          color: _speakerColor(state.speakerState),
          height: 48,
          barCount: 26,
        ),
        const SizedBox(height: 6),
        Text(
          isAiSpeaking
              ? 'Kênh phát Tom (TTS)'
              : (isUserSpeaking
                  ? 'Kênh nói của Bạn (Mic)'
                  : 'Đang chờ giọng nói'),
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
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            AdaptiveRow(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: state.currentSpeakerRole == 'ai'
                          ? AppColors.primaryLight
                          : AppColors.userWaveform,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.currentSpeakerRole == 'ai' ? 'Coach Tom' : 'Bạn',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: state.currentSpeakerRole == 'ai'
                            ? AppColors.primaryLight
                            : AppColors.userWaveform,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 14, color: Colors.white60),
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

  Widget _buildCallControls(BuildContext context, RealtimeCallState state,
      RealtimeCallController controller) {
    final disabled = _endingCall ||
        state.isCallEnded ||
        state.speakerState == RealtimeSpeakerState.ended;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 14,
          children: [
            _control(
                label: 'Micro',
                hint: state.isMuted ? 'Bật micro' : 'Tắt micro',
                icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: state.isMuted ? const Color(0xFFFFA3AE) : Colors.white,
                selected: state.isMuted,
                onPressed: disabled ? null : controller.toggleMute),
            _control(
                label: 'Loa',
                hint: state.isSpeakerPhoneOn
                    ? 'Chuyển sang loa trong'
                    : 'Bật loa ngoài',
                icon: state.isSpeakerPhoneOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                selected: state.isSpeakerPhoneOn,
                onPressed: disabled ? null : controller.toggleSpeakerPhone),
            _control(
                label: 'Phụ đề',
                hint: state.showCaptions ? 'Ẩn phụ đề' : 'Hiện phụ đề',
                icon: state.showCaptions
                    ? Icons.subtitles_rounded
                    : Icons.subtitles_off_rounded,
                selected: state.showCaptions,
                onPressed: disabled ? null : controller.toggleCaptions),
            _control(
                label: 'Kết thúc',
                hint: 'Kết thúc cuộc gọi',
                icon: Icons.call_end_rounded,
                destructive: true,
                onPressed: disabled ? null : () => _confirmEndCall(controller)),
          ]),
    );
  }

  Widget _control(
      {required String label,
      required String hint,
      required IconData icon,
      required VoidCallback? onPressed,
      Color color = Colors.white,
      bool selected = false,
      bool destructive = false}) {
    return SizedBox(
        width: 66,
        child: Column(children: [
          IconButton.filledTonal(
              tooltip: hint,
              isSelected: selected,
              onPressed: onPressed,
              style: IconButton.styleFrom(
                backgroundColor: destructive
                    ? const Color(0xFFC63F54)
                    : selected
                        ? const Color(0xFF364962)
                        : const Color(0xFF233247),
                disabledBackgroundColor: const Color(0xFF263141),
                minimumSize: const Size(54, 54),
              ),
              icon: Icon(icon,
                  size: 25, color: onPressed == null ? Colors.white38 : color)),
          const SizedBox(height: 7),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]));
  }
}
