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
    this.confidence = 0.0,
    required this.feedbackVi,
    this.evidenceSnippets = const [],
    this.hasAcousticEvidence = false,
  });

  bool get isAvailable =>
      estimatedBand != null &&
      estimatedBand!.isFinite &&
      estimatedBand! >= 0 &&
      estimatedBand! <= 9 &&
      confidence.isFinite &&
      confidence > 0 &&
      confidence <= 1 &&
      evidenceSnippets.any((snippet) => snippet.trim().isNotEmpty) &&
      (dimension != RubricDimension.pronunciation || hasAcousticEvidence);

  String get displayBand =>
      isAvailable ? estimatedBand!.toStringAsFixed(1) : 'N/A';
}

/// Comprehensive Post-Session Assessment Report
class AssessmentReport {
  final String id;
  final String sessionId;
  final double? _overallEstimatedBand;
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
    double? overallEstimatedBand,
    required this.summaryVi,
    this.strengths = const [],
    this.improvements = const [],
    required this.dimensions,
    this.corrections = const [],
    this.rubricVersion = 'v1.1.0',
    required this.createdAt,
  }) : _overallEstimatedBand = overallEstimatedBand;

  double? get overallEstimatedBand {
    final band = _overallEstimatedBand;
    if (band == null || !band.isFinite || band < 0 || band > 9) return null;
    for (final dimension in RubricDimension.values) {
      final score = dimensions[dimension];
      if (score == null || score.dimension != dimension || !score.isAvailable) {
        return null;
      }
    }
    return band;
  }

  String get displayOverall => overallEstimatedBand != null
      ? overallEstimatedBand!.toStringAsFixed(1)
      : 'N/A';
}
