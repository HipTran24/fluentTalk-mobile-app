import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/guided_repository.dart';
import '../../domain/models/guided_models.dart';

final guidedSpeakingRepositoryProvider =
    Provider<GuidedSpeakingRepository>((ref) {
  return MockGuidedSpeakingRepository();
});

class GuidedSpeakingState {
  final String scenarioId;
  final String sessionId;
  final List<GuidedTurn> turns;
  final int currentTurnIndex;
  final RecordingState recordingState;
  final bool isAiSpeaking;
  final double aiSpeechRate;
  final bool showAiTranslation;
  final int recordingDurationSeconds;
  final String currentTranscriptDraft;
  final TurnFeedback? latestFeedback;
  final String? errorMessage;
  final bool isCompleted;
  final bool isLoading;

  const GuidedSpeakingState({
    required this.scenarioId,
    required this.sessionId,
    this.turns = const [],
    this.currentTurnIndex = 0,
    this.recordingState = RecordingState.idle,
    this.isAiSpeaking = false,
    this.aiSpeechRate = 1.0,
    this.showAiTranslation = false,
    this.recordingDurationSeconds = 0,
    this.currentTranscriptDraft = '',
    this.latestFeedback,
    this.errorMessage,
    this.isCompleted = false,
    this.isLoading = true,
  });

  GuidedTurn? get currentTurn {
    if (turns.isEmpty || currentTurnIndex >= turns.length) return null;
    return turns[currentTurnIndex];
  }

  int get totalTurns => turns.length;
  double get progressPercentage =>
      turns.isEmpty ? 0.0 : (currentTurnIndex + 1) / turns.length;

  GuidedSpeakingState copyWith({
    String? scenarioId,
    String? sessionId,
    List<GuidedTurn>? turns,
    int? currentTurnIndex,
    RecordingState? recordingState,
    bool? isAiSpeaking,
    double? aiSpeechRate,
    bool? showAiTranslation,
    int? recordingDurationSeconds,
    String? currentTranscriptDraft,
    TurnFeedback? latestFeedback,
    bool clearFeedback = false,
    String? errorMessage,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return GuidedSpeakingState(
      scenarioId: scenarioId ?? this.scenarioId,
      sessionId: sessionId ?? this.sessionId,
      turns: turns ?? this.turns,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      recordingState: recordingState ?? this.recordingState,
      isAiSpeaking: isAiSpeaking ?? this.isAiSpeaking,
      aiSpeechRate: aiSpeechRate ?? this.aiSpeechRate,
      showAiTranslation: showAiTranslation ?? this.showAiTranslation,
      recordingDurationSeconds:
          recordingDurationSeconds ?? this.recordingDurationSeconds,
      currentTranscriptDraft:
          currentTranscriptDraft ?? this.currentTranscriptDraft,
      latestFeedback:
          clearFeedback ? null : (latestFeedback ?? this.latestFeedback),
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final guidedSpeakingControllerProvider = StateNotifierProvider.family<
    GuidedSpeakingController, GuidedSpeakingState, String>((ref, scenarioId) {
  final repo = ref.watch(guidedSpeakingRepositoryProvider);
  return GuidedSpeakingController(repo, scenarioId);
});

class GuidedSpeakingController extends StateNotifier<GuidedSpeakingState> {
  final GuidedSpeakingRepository _repository;
  Timer? _recordingTimer;

  GuidedSpeakingController(this._repository, String scenarioId)
      : super(GuidedSpeakingState(
          scenarioId: scenarioId,
          sessionId: 'sess_guided_${DateTime.now().millisecondsSinceEpoch}',
        )) {
    loadSession();
  }

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final turns = await _repository.getTurnsForScenario(state.scenarioId);
      if (!mounted) return;
      state = state.copyWith(
        turns: turns,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải nội dung kịch bản. Vui lòng thử lại.',
      );
    }
  }

  void toggleAiSpeaking() {
    state = state.copyWith(isAiSpeaking: !state.isAiSpeaking);
  }

  void setAiSpeechRate(double rate) {
    state = state.copyWith(aiSpeechRate: rate);
  }

  void toggleTranslation() {
    state = state.copyWith(showAiTranslation: !state.showAiTranslation);
  }

  void startRecording() {
    if (state.recordingState == RecordingState.recording) return;

    _recordingTimer?.cancel();
    state = state.copyWith(
      recordingState: RecordingState.recording,
      recordingDurationSeconds: 0,
      errorMessage: null,
      clearFeedback: true,
    );

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      state = state.copyWith(
          recordingDurationSeconds: state.recordingDurationSeconds + 1);

      // Max turn duration 45s safety auto-stop
      if (state.recordingDurationSeconds >= 45) {
        stopRecording();
      }
    });
  }

  Future<void> stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (state.recordingState != RecordingState.recording) return;

    state = state.copyWith(recordingState: RecordingState.transcribing);

    try {
      final transcript = await _repository.transcribeAudio(
        scenarioId: state.scenarioId,
        turnIndex: state.currentTurnIndex + 1,
      );

      if (!mounted) return;
      state = state.copyWith(
        recordingState: RecordingState.reviewing,
        currentTranscriptDraft: transcript,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        recordingState: RecordingState.idle,
        errorMessage: 'Không thể nhận diện giọng nói. Bạn hãy thử nói lại nhé.',
      );
    }
  }

  void updateTranscriptDraft(String newText) {
    state = state.copyWith(currentTranscriptDraft: newText);
  }

  void recordAgain() {
    _recordingTimer?.cancel();
    state = state.copyWith(
      recordingState: RecordingState.idle,
      currentTranscriptDraft: '',
      recordingDurationSeconds: 0,
      clearFeedback: true,
      errorMessage: null,
    );
  }

  Future<void> submitTurn() async {
    final text = state.currentTranscriptDraft.trim();
    if (text.isEmpty) return;

    state = state.copyWith(
        recordingState: RecordingState.evaluating, errorMessage: null);

    try {
      final feedback = await _repository.evaluateTurn(
        scenarioId: state.scenarioId,
        turnIndex: state.currentTurnIndex + 1,
        userTranscript: text,
      );

      if (!mounted) return;

      // Update current turn with user transcript and feedback
      final updatedTurns = [...state.turns];
      final current = updatedTurns[state.currentTurnIndex];
      updatedTurns[state.currentTurnIndex] = current.copyWith(
        userTranscript: text,
        audioDurationSeconds: state.recordingDurationSeconds,
        feedback: feedback,
        isCompleted: true,
      );

      state = state.copyWith(
        turns: updatedTurns,
        latestFeedback: feedback,
        recordingState: RecordingState.idle,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        recordingState: RecordingState.reviewing,
        errorMessage: 'Chưa thể đánh giá lượt nói. Vui lòng bấm gửi lại.',
      );
    }
  }

  Future<void> nextTurn() async {
    if (state.currentTurnIndex + 1 < state.turns.length) {
      // Next turn
      state = state.copyWith(
        currentTurnIndex: state.currentTurnIndex + 1,
        recordingState: RecordingState.idle,
        currentTranscriptDraft: '',
        recordingDurationSeconds: 0,
        clearFeedback: true,
        isAiSpeaking: false,
      );
    } else {
      // Completed all turns!
      state = state.copyWith(isLoading: true);
      await _repository.saveCompletedSession(
        sessionId: state.sessionId,
        scenarioId: state.scenarioId,
        completedTurns: state.turns,
      );
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isCompleted: true,
      );
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}
