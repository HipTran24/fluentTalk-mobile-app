import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/realtime_repository.dart';
import '../../domain/models/realtime_models.dart';

final realtimeCallRepositoryProvider = Provider<RealtimeCallRepository>((ref) {
  return MockRealtimeCallRepository();
});

class RealtimeCallState {
  final String sessionId;
  final RealtimeSpeakerState speakerState;
  final int callDurationSeconds;
  final bool isMuted;
  final bool isSpeakerPhoneOn;
  final bool showCaptions;
  final List<RealtimeCaptionItem> captionsHistory;
  final String currentSpeakerText;
  final String currentSpeakerRole; // 'ai' or 'user'
  final List<ConversationTopicHint> topicHints;
  final int latencyMs;
  final bool isCallEnded;

  const RealtimeCallState({
    required this.sessionId,
    this.speakerState = RealtimeSpeakerState.connecting,
    this.callDurationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerPhoneOn = true,
    this.showCaptions = true,
    this.captionsHistory = const [],
    this.currentSpeakerText = 'Đang thiết lập kênh thoại 2 chiều...',
    this.currentSpeakerRole = 'ai',
    this.topicHints = const [],
    this.latencyMs = 45,
    this.isCallEnded = false,
  });

  String get formattedDuration {
    final minutes = (callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  RealtimeCallState copyWith({
    String? sessionId,
    RealtimeSpeakerState? speakerState,
    int? callDurationSeconds,
    bool? isMuted,
    bool? isSpeakerPhoneOn,
    bool? showCaptions,
    List<RealtimeCaptionItem>? captionsHistory,
    String? currentSpeakerText,
    String? currentSpeakerRole,
    List<ConversationTopicHint>? topicHints,
    int? latencyMs,
    bool? isCallEnded,
  }) {
    return RealtimeCallState(
      sessionId: sessionId ?? this.sessionId,
      speakerState: speakerState ?? this.speakerState,
      callDurationSeconds: callDurationSeconds ?? this.callDurationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerPhoneOn: isSpeakerPhoneOn ?? this.isSpeakerPhoneOn,
      showCaptions: showCaptions ?? this.showCaptions,
      captionsHistory: captionsHistory ?? this.captionsHistory,
      currentSpeakerText: currentSpeakerText ?? this.currentSpeakerText,
      currentSpeakerRole: currentSpeakerRole ?? this.currentSpeakerRole,
      topicHints: topicHints ?? this.topicHints,
      latencyMs: latencyMs ?? this.latencyMs,
      isCallEnded: isCallEnded ?? this.isCallEnded,
    );
  }
}

final realtimeCallControllerProvider = StateNotifierProvider.family<
    RealtimeCallController, RealtimeCallState, String>((ref, sessionId) {
  final repo = ref.watch(realtimeCallRepositoryProvider);
  return RealtimeCallController(repo, sessionId);
});

class RealtimeCallController extends StateNotifier<RealtimeCallState> {
  final RealtimeCallRepository _repository;
  Timer? _callTimer;
  Timer? _speakerSimulationTimer;

  RealtimeCallController(this._repository, String sessionId)
      : super(RealtimeCallState(sessionId: sessionId)) {
    initCall();
  }

  Future<void> initCall() async {
    final hints = await _repository.getTopicHints(state.sessionId);
    final initialCaps =
        await _repository.getInitialConversation(state.sessionId);

    if (!mounted) return;

    state = state.copyWith(
      speakerState: RealtimeSpeakerState.aiSpeaking,
      topicHints: hints,
      captionsHistory: initialCaps,
      currentSpeakerText: initialCaps.isNotEmpty
          ? initialCaps.last.text
          : 'Hello! I am Tom. How has your day been so far?',
      currentSpeakerRole: 'ai',
      latencyMs: 42,
    );

    // Start Call Duration Timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      state =
          state.copyWith(callDurationSeconds: state.callDurationSeconds + 1);
    });

    // Schedule natural transition from initial greeting to listening
    _speakerSimulationTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (state.speakerState == RealtimeSpeakerState.aiSpeaking) {
        state = state.copyWith(
          speakerState: RealtimeSpeakerState.listening,
          currentSpeakerText: 'Tom đang lắng nghe bạn nói...',
          currentSpeakerRole: 'user',
        );
      }
    });
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleSpeakerPhone() {
    state = state.copyWith(isSpeakerPhoneOn: !state.isSpeakerPhoneOn);
  }

  void toggleCaptions() {
    state = state.copyWith(showCaptions: !state.showCaptions);
  }

  /// User starts speaking (Full-Duplex VAD / Barge-In)
  void simulateUserSpeech(String text) {
    if (state.isMuted) return;

    _speakerSimulationTimer?.cancel();

    final userCap = RealtimeCaptionItem(
      id: 'cap_${DateTime.now().millisecondsSinceEpoch}',
      speaker: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      speakerState: RealtimeSpeakerState.userSpeaking,
      currentSpeakerRole: 'user',
      currentSpeakerText: text,
      captionsHistory: [...state.captionsHistory, userCap],
    );

    // After user finishes, Tom enters thinking then speaks
    _speakerSimulationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      state = state.copyWith(
        speakerState: RealtimeSpeakerState.aiThinking,
        currentSpeakerRole: 'ai',
        currentSpeakerText: 'Tom đang suy nghĩ câu trả lời phản xạ...',
      );

      _speakerSimulationTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        final aiReplies = [
          'That sounds really fascinating! Did you get a chance to take photos of that?',
          'I completely agree with you! How did that make you feel at that moment?',
          'That is a great observation. In my experience, people often feel the same way!',
        ];
        final replyText =
            aiReplies[state.captionsHistory.length % aiReplies.length];

        final aiCap = RealtimeCaptionItem(
          id: 'cap_ai_${DateTime.now().millisecondsSinceEpoch}',
          speaker: 'ai',
          text: replyText,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          speakerState: RealtimeSpeakerState.aiSpeaking,
          currentSpeakerRole: 'ai',
          currentSpeakerText: replyText,
          captionsHistory: [...state.captionsHistory, aiCap],
        );

        // Then back to listening
        _speakerSimulationTimer = Timer(const Duration(seconds: 4), () {
          if (!mounted) return;
          state = state.copyWith(
            speakerState: RealtimeSpeakerState.listening,
            currentSpeakerRole: 'user',
            currentSpeakerText: 'Tom đang lắng nghe bạn nói...',
          );
        });
      });
    });
  }

  /// Barge-in / Interrupt: User immediately stops Tom from speaking
  void interruptAi() {
    if (state.speakerState == RealtimeSpeakerState.aiSpeaking) {
      _speakerSimulationTimer?.cancel();
      state = state.copyWith(
        speakerState: RealtimeSpeakerState.listening,
        currentSpeakerRole: 'user',
        currentSpeakerText:
            'Đã ngắt lời Tom. Tom đang lắng nghe bạn tiếp tục...',
      );
    }
  }

  Future<void> endCall() async {
    _callTimer?.cancel();
    _speakerSimulationTimer?.cancel();

    state = state.copyWith(speakerState: RealtimeSpeakerState.ended);
    await _repository.endCallSession(
        state.sessionId, state.callDurationSeconds);

    if (!mounted) return;
    state = state.copyWith(isCallEnded: true);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _speakerSimulationTimer?.cancel();
    super.dispose();
  }
}
