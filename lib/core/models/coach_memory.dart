import 'enums.dart';

/// Weakness identified by Coach Memory Engine
class WeaknessItem {
  final String id;
  final String category;
  final String description;
  final String evidence;
  final int recurrenceCount;
  final double impact;
  final double confidence;
  final DateTime lastObservedAt;

  const WeaknessItem({
    required this.id,
    required this.category,
    required this.description,
    required this.evidence,
    this.recurrenceCount = 1,
    this.impact = 0.8,
    this.confidence = 0.9,
    required this.lastObservedAt,
  });
}

/// Corrective 3-5 minute micro-drill
class RemedialDrill {
  final String id;
  final String title;
  final String objective;
  final String weaknessCategory;
  final UserLevel level;
  final String taskType; // listen_repeat, shadowing, reorder, roleplay
  final int estimatedMinutes;
  final String targetPhrase;
  final String? audioPromptUrl;

  const RemedialDrill({
    required this.id,
    required this.title,
    required this.objective,
    required this.weaknessCategory,
    required this.level,
    required this.taskType,
    this.estimatedMinutes = 3,
    required this.targetPhrase,
    this.audioPromptUrl,
  });
}

/// Day item in 7-day personalized plan
class WeeklyPlanItem {
  final String id;
  final int dayIndex; // 1 to 7 (Monday to Sunday)
  final String dayName;
  final String title;
  final String activityType; // scenario, drill, review
  final int estimatedMinutes;
  final bool isCompleted;
  final bool isToday;

  const WeeklyPlanItem({
    required this.id,
    required this.dayIndex,
    required this.dayName,
    required this.title,
    required this.activityType,
    required this.estimatedMinutes,
    this.isCompleted = false,
    this.isToday = false,
  });
}
