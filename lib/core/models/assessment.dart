import 'enums.dart';
import 'practice_session.dart';

/// Single Rubric Dimension Score
class DimensionScore {
  final RubricDimension dimension;
  final double? estimatedBand; // 0.0 - 9.0 or null if N/A
  final double confidence; // 0.0 - 1.0
  final String feedbackVi;
  final List<String> evidenceSnippets;
  final bool hasAcousticEvidence;

  const DimensionScore({
    required this.dimension,
    this.estimatedBand,
    this.confidence = 0.85,
    required this.feedbackVi,
    this.evidenceSnippets = const [],
    this.hasAcousticEvidence = false,
  });

  bool get isAvailable => estimatedBand != null;
  String get displayBand => estimatedBand != null ? estimatedBand!.toStringAsFixed(1) : 'N/A';
}

/// Comprehensive Post-Session Assessment Report
class AssessmentReport {
  final String id;
  final String sessionId;
  final double? overallEstimatedBand;
  final String summaryVi;
  final List<String> strengths;
  final List<String> improvements;
  final Map<RubricDimension, DimensionScore> dimensions;
  final List<CorrectionItem> corrections;
  final String rubricVersion;
  final DateTime createdAt;

  const AssessmentReport({
    required this.id,
    required this.sessionId,
    this.overallEstimatedBand,
    required this.summaryVi,
    this.strengths = const [],
    this.improvements = const [],
    required this.dimensions,
    this.corrections = const [],
    this.rubricVersion = 'v1.1.0',
    required this.createdAt,
  });

  String get displayOverall =>
      overallEstimatedBand != null ? overallEstimatedBand!.toStringAsFixed(1) : 'Tham khảo';
}
