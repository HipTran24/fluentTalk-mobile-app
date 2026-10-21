import '../../../../core/models/scenario.dart';

/// Single Turn in Mode 2: Guided Speaking
/// Compliant with ESP-PLAN-001 Appendix B11 & MODE-02
class GuidedTurn {
  final int turnIndex; // 1-indexed (e.g. 1, 2, 3...)
  final String aiRole;
  final String aiPromptEn;
  final String aiPromptVi;
  final String? aiPromptIpa;
  final String? aiAudioUrl;
  final String userRole;
  final String userGoalVi;
  final List<String> suggestedStarters;
  final List<VocabularyPreviewItem> keyVocabulary;
  final String? userTranscript;
  final int? audioDurationSeconds;
  final TurnFeedback? feedback;
  final bool isCompleted;

  const GuidedTurn({
    required this.turnIndex,
    required this.aiRole,
    required this.aiPromptEn,
    required this.aiPromptVi,
    this.aiPromptIpa,
    this.aiAudioUrl,
    required this.userRole,
    required this.userGoalVi,
    this.suggestedStarters = const [],
    this.keyVocabulary = const [],
    this.userTranscript,
    this.audioDurationSeconds,
    this.feedback,
    this.isCompleted = false,
  });

  GuidedTurn copyWith({
    int? turnIndex,
    String? aiRole,
    String? aiPromptEn,
    String? aiPromptVi,
    String? aiPromptIpa,
    String? aiAudioUrl,
    String? userRole,
    String? userGoalVi,
    List<String>? suggestedStarters,
    List<VocabularyPreviewItem>? keyVocabulary,
    String? userTranscript,
    int? audioDurationSeconds,
    TurnFeedback? feedback,
    bool? isCompleted,
  }) {
    return GuidedTurn(
      turnIndex: turnIndex ?? this.turnIndex,
      aiRole: aiRole ?? this.aiRole,
      aiPromptEn: aiPromptEn ?? this.aiPromptEn,
      aiPromptVi: aiPromptVi ?? this.aiPromptVi,
      aiPromptIpa: aiPromptIpa ?? this.aiPromptIpa,
      aiAudioUrl: aiAudioUrl ?? this.aiAudioUrl,
      userRole: userRole ?? this.userRole,
      userGoalVi: userGoalVi ?? this.userGoalVi,
      suggestedStarters: suggestedStarters ?? this.suggestedStarters,
      keyVocabulary: keyVocabulary ?? this.keyVocabulary,
      userTranscript: userTranscript ?? this.userTranscript,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      feedback: feedback ?? this.feedback,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Instant feedback on an individual turn
class TurnFeedback {
  final double score; // 0 to 100
  final String praise;
  final String? nativeAlternative;
  final List<String> usedKeywords;
  final String pronunciationNotes;

  const TurnFeedback({
    required this.score,
    required this.praise,
    this.nativeAlternative,
    this.usedKeywords = const [],
    this.pronunciationNotes = 'Phát âm rõ ràng, ngữ điệu tự nhiên.',
  });
}

/// Audio Recording State
enum RecordingState {
  idle,
  recording,
  transcribing,
  reviewing,
  evaluating,
}
