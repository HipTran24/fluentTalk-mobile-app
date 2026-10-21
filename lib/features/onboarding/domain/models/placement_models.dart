import '../../../../core/models/enums.dart';

/// Question item for audio-based placement test
class PlacementQuestion {
  final String id;
  final UserLevel targetLevel;
  final String title;
  final String promptEn;
  final String promptVi;
  final int timeLimitSeconds;
  final List<String> sampleKeyPhrases;

  const PlacementQuestion({
    required this.id,
    required this.targetLevel,
    required this.title,
    required this.promptEn,
    required this.promptVi,
    this.timeLimitSeconds = 30,
    this.sampleKeyPhrases = const [],
  });
}

/// Recorded answer for a placement question
class PlacementAnswer {
  final String questionId;
  final String transcript;
  final double confidence;
  final bool hasAudio;

  const PlacementAnswer({
    required this.questionId,
    required this.transcript,
    this.confidence = 0.85,
    this.hasAudio = true,
  });
}

/// Computed level placement result
class PlacementResult {
  final UserLevel estimatedLevel;
  final double confidence;
  final String evaluationSummary;
  final List<String> identifiedStrengths;
  final List<String> recommendedNextSteps;
  final String disclaimer;

  const PlacementResult({
    required this.estimatedLevel,
    required this.confidence,
    required this.evaluationSummary,
    this.identifiedStrengths = const [],
    this.recommendedNextSteps = const [],
    this.disclaimer =
        'Đánh giá phản xạ được thực hiện bởi AI Coach nội bộ dựa trên các mẫu nói thực nghiệm. Đây là kết quả tham khảo học tập, không thay thế chứng chỉ CEFR hay kỳ thi IELTS chính thức.',
  });
}
