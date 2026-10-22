import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/coach_memory.dart';
import '../../data/coach_repository.dart';

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return MockCoachRepository();
});

final coachWeaknessesProvider = FutureProvider<List<WeaknessItem>>((ref) async {
  final repo = ref.watch(coachRepositoryProvider);
  return repo.getIdentifiedWeaknesses();
});

final weeklyPlanProvider = FutureProvider<List<WeeklyPlanItem>>((ref) async {
  final repo = ref.watch(coachRepositoryProvider);
  return repo.getWeeklyPlan();
});

class DrillPlayerState {
  final RemedialDrill? drill;
  final int currentStep;
  final int totalSteps;
  final bool isRecording;
  final bool hasResult;
  final String? spokenTranscript;
  final double score;
  final bool isCompleted;
  final bool isLoading;

  const DrillPlayerState({
    this.drill,
    this.currentStep = 1,
    this.totalSteps = 3,
    this.isRecording = false,
    this.hasResult = false,
    this.spokenTranscript,
    this.score = 0.0,
    this.isCompleted = false,
    this.isLoading = true,
  });

  DrillPlayerState copyWith({
    RemedialDrill? drill,
    int? currentStep,
    int? totalSteps,
    bool? isRecording,
    bool? hasResult,
    String? spokenTranscript,
    double? score,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return DrillPlayerState(
      drill: drill ?? this.drill,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isRecording: isRecording ?? this.isRecording,
      hasResult: hasResult ?? this.hasResult,
      spokenTranscript: spokenTranscript ?? this.spokenTranscript,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final drillPlayerControllerProvider = StateNotifierProvider.family<
    DrillPlayerController, DrillPlayerState, String>(
  (ref, drillId) {
    final repo = ref.watch(coachRepositoryProvider);
    return DrillPlayerController(repo, drillId);
  },
);

class DrillPlayerController extends StateNotifier<DrillPlayerState> {
  final CoachRepository _repository;
  final String drillId;

  DrillPlayerController(this._repository, this.drillId)
      : super(const DrillPlayerState()) {
    loadDrill();
  }

  Future<void> loadDrill() async {
    state = state.copyWith(isLoading: true);
    final drill = await _repository.getDrillById(drillId);
    if (!mounted) return;
    state = state.copyWith(drill: drill, isLoading: false);
  }

  void startRecording() {
    state = state.copyWith(isRecording: true, hasResult: false);
  }

  Future<void> stopRecording() async {
    state = state.copyWith(isRecording: false);
    // Simulate Speech-to-text and scoring
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final target =
        state.drill?.targetPhrase ?? 'Yesterday, I went to the supermarket.';
    state = state.copyWith(
      hasResult: true,
      spokenTranscript: target,
      score: 95.0,
    );
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        hasResult: false,
        spokenTranscript: null,
        score: 0.0,
      );
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }
}
