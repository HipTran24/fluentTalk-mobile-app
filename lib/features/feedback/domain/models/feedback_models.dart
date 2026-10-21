import '../../../../core/models/assessment.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/practice_session.dart';

/// Full Session Report for Screen 13
/// Compliant with ESP-PLAN-001 Appendix A5 & B15
class SessionReport {
  final String sessionId;
  final String scenarioTitle;
  final SessionMode mode;
  final DateTime completedAt;
  final int durationSeconds;
  final int turnsCount;
  final double overallBand;
  final UserLevel cefrLevel;
  final List<DimensionScore> dimensionScores;
  final List<CorrectionItem> keyCorrections;
  final String coachAdviceVi;
  final String recommendedDrillId;
  final String recommendedDrillTitle;

  const SessionReport({
    required this.sessionId,
    required this.scenarioTitle,
    required this.mode,
    required this.completedAt,
    required this.durationSeconds,
    required this.turnsCount,
    required this.overallBand,
    required this.cefrLevel,
    required this.dimensionScores,
    required this.keyCorrections,
    required this.coachAdviceVi,
    required this.recommendedDrillId,
    required this.recommendedDrillTitle,
  });

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m}m ${s}s';
  }
}

/// Daily speaking bar for Bar Chart in Screen 14
class DailyPracticeBar {
  final String dayLabel; // 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'
  final int minutes;
  final bool isToday;

  const DailyPracticeBar({
    required this.dayLabel,
    required this.minutes,
    this.isToday = false,
  });
}

/// Learning Analytics Data for Screen 14
class ProgressAnalyticsData {
  final int totalMinutes;
  final int totalSessions;
  final int currentStreak;
  final List<DailyPracticeBar> weeklyBars;
  final Map<RubricDimension, double> currentBands;
  final Map<RubricDimension, double> bandGrowth; // e.g. +0.5

  const ProgressAnalyticsData({
    required this.totalMinutes,
    required this.totalSessions,
    required this.currentStreak,
    required this.weeklyBars,
    required this.currentBands,
    required this.bandGrowth,
  });
}
