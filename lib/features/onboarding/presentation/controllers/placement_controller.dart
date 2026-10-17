import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../domain/models/placement_models.dart';

final placementQuestionsProvider = Provider<List<PlacementQuestion>>((ref) {
  return const [
    PlacementQuestion(
      id: 'q1',
      targetLevel: UserLevel.a1,
      title: 'Câu hỏi 1: Giới thiệu bản thân',
      promptEn: 'Please introduce yourself. Mention your name, where you live, and what you do for fun.',
      promptVi: 'Hãy giới thiệu ngắn về bản thân: tên, nơi bạn đang sống và một sở thích lúc rảnh rỗi.',
      timeLimitSeconds: 30,
      sampleKeyPhrases: ['My name is...', 'I live in...', 'In my free time, I enjoy...'],
    ),
    PlacementQuestion(
      id: 'q2',
      targetLevel: UserLevel.a2,
      title: 'Câu hỏi 2: Kể về cuối tuần',
      promptEn: 'Tell me about what you usually do on weekends and why you enjoy those activities.',
      promptVi: 'Hãy chia sẻ về các hoạt động bạn thường làm vào thứ Bảy hoặc Chủ Nhật và lý do bạn thích chúng.',
      timeLimitSeconds: 40,
      sampleKeyPhrases: ['On Saturday mornings, I usually...', 'It helps me relax because...'],
    ),
    PlacementQuestion(
      id: 'q3',
      targetLevel: UserLevel.b1,
      title: 'Câu hỏi 3: Trình bày quan điểm',
      promptEn: 'In your opinion, what are the advantages and challenges of learning English using an AI app?',
      promptVi: 'Theo bạn, việc tự luyện nói tiếng Anh với ứng dụng AI có những điểm thuận lợi và thử thách nào?',
      timeLimitSeconds: 45,
      sampleKeyPhrases: ['In my opinion...', 'One major advantage is...', 'However, learners need to...'],
    ),
  ];
});

class PlacementState {
  final int currentStep; // 0: Question 1, 1: Question 2, 2: Question 3, 3: Result
  final Map<String, PlacementAnswer> answers;
  final bool isRecording;
  final bool isAnalyzing;
  final PlacementResult? result;
  final UserLevel selectedManualLevel;
  final bool isManualMode;

  const PlacementState({
    this.currentStep = 0,
    this.answers = const {},
    this.isRecording = false,
    this.isAnalyzing = false,
    this.result,
    this.selectedManualLevel = UserLevel.a2,
    this.isManualMode = false,
  });

  PlacementState copyWith({
    int? currentStep,
    Map<String, PlacementAnswer>? answers,
    bool? isRecording,
    bool? isAnalyzing,
    PlacementResult? result,
    UserLevel? selectedManualLevel,
    bool? isManualMode,
  }) {
    return PlacementState(
      currentStep: currentStep ?? this.currentStep,
      answers: answers ?? this.answers,
      isRecording: isRecording ?? this.isRecording,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: result ?? this.result,
      selectedManualLevel: selectedManualLevel ?? this.selectedManualLevel,
      isManualMode: isManualMode ?? this.isManualMode,
    );
  }
}

final placementControllerProvider = StateNotifierProvider<PlacementController, PlacementState>((ref) {
  final questions = ref.watch(placementQuestionsProvider);
  return PlacementController(questions);
});

class PlacementController extends StateNotifier<PlacementState> {
  final List<PlacementQuestion> questions;

  PlacementController(this.questions) : super(const PlacementState());

  void toggleManualMode(bool isManual) {
    state = state.copyWith(isManualMode: isManual);
  }

  void selectManualLevel(UserLevel level) {
    state = state.copyWith(selectedManualLevel: level);
  }

  void setRecording(bool recording) {
    state = state.copyWith(isRecording: recording);
  }

  void submitAnswer(String questionId, String transcript) {
    final updatedAnswers = Map<String, PlacementAnswer>.from(state.answers);
    updatedAnswers[questionId] = PlacementAnswer(
      questionId: questionId,
      transcript: transcript,
      confidence: 0.88,
    );
    state = state.copyWith(answers: updatedAnswers);
  }

  Future<void> nextStep() async {
    if (state.currentStep < questions.length - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    } else {
      // Analyze and calculate results
      await calculateResult();
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> calculateResult() async {
    state = state.copyWith(isAnalyzing: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    // Evaluate answers
    final totalAnswers = state.answers.length;
    UserLevel calculatedLevel = UserLevel.a2;

    if (totalAnswers >= 3) {
      calculatedLevel = UserLevel.b1;
    } else if (totalAnswers == 2) {
      calculatedLevel = UserLevel.a2;
    } else {
      calculatedLevel = UserLevel.a1;
    }

    final result = PlacementResult(
      estimatedLevel: calculatedLevel,
      confidence: 0.86,
      evaluationSummary:
          'Bạn phát âm rõ ràng các âm nguyên âm cơ bản, có khả năng diễn đạt ý trọn vẹn ở các chủ đề quen thuộc.',
      identifiedStrengths: [
        'Ngữ điệu câu hỏi và câu trần thuật tự nhiên.',
        'Sử dụng đúng thì Hiện tại đơn và các liên từ cơ bản (and, but, because).',
      ],
      recommendedNextSteps: [
        'Bổ sung thì Quá khứ đơn để kể lại các trải nghiệm sinh động hơn.',
        'Mở rộng vốn từ vựng miêu tả cảm xúc và quan điểm cá nhân.',
      ],
    );

    state = state.copyWith(
      isAnalyzing: false,
      result: result,
      currentStep: questions.length, // Move to results step
    );
  }

  void resetTest() {
    state = const PlacementState();
  }
}
