import 'package:english_mobile_app/core/models/enums.dart';

/// KPI Summary Data for Executive Admin Dashboard
class AdminKpiSummary {
  final int totalLearners;
  final double learnerGrowthPct;
  final int totalVoiceMinutes;
  final double voiceGrowthPct;
  final int activeSessionsToday;
  final String geminiTokensUsed;
  final double avgFluencyScore;
  final List<AdminDailyMetric> weeklyTrends;
  final List<AdminActivityItem> recentActivities;

  const AdminKpiSummary({
    required this.totalLearners,
    required this.learnerGrowthPct,
    required this.totalVoiceMinutes,
    required this.voiceGrowthPct,
    required this.activeSessionsToday,
    required this.geminiTokensUsed,
    required this.avgFluencyScore,
    required this.weeklyTrends,
    required this.recentActivities,
  });
}

class AdminDailyMetric {
  final String dayLabel;
  final int voiceMinutes;
  final int sessionCount;

  const AdminDailyMetric({
    required this.dayLabel,
    required this.voiceMinutes,
    required this.sessionCount,
  });
}

class AdminActivityItem {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  final String type; // 'session', 'signup', 'ai_drill', 'alert'

  const AdminActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.type,
  });
}

/// Learner Profile in User Management Directory
class AdminLearner {
  final String id;
  final String name;
  final String email;
  final UserLevel level;
  final LearningGoalType goal;
  final int totalSessions;
  final int voiceMinutes;
  final int streakDays;
  final bool isActive;
  final DateTime lastActiveAt;

  const AdminLearner({
    required this.id,
    required this.name,
    required this.email,
    required this.level,
    required this.goal,
    required this.totalSessions,
    required this.voiceMinutes,
    required this.streakDays,
    required this.isActive,
    required this.lastActiveAt,
  });

  AdminLearner copyWith({
    String? id,
    String? name,
    String? email,
    UserLevel? level,
    LearningGoalType? goal,
    int? totalSessions,
    int? voiceMinutes,
    int? streakDays,
    bool? isActive,
    DateTime? lastActiveAt,
  }) {
    return AdminLearner(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      level: level ?? this.level,
      goal: goal ?? this.goal,
      totalSessions: totalSessions ?? this.totalSessions,
      voiceMinutes: voiceMinutes ?? this.voiceMinutes,
      streakDays: streakDays ?? this.streakDays,
      isActive: isActive ?? this.isActive,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

/// Admin Scenario CMS Model
class AdminScenarioItem {
  final String id;
  final String title;
  final String topicId;
  final String topicName;
  final UserLevel level;
  final String aiRole;
  final String userRole;
  final int estimatedMinutes;
  final int usageCount;
  final double avgScore;
  final bool isActive;
  final List<String> keyPhrases;

  const AdminScenarioItem({
    required this.id,
    required this.title,
    required this.topicId,
    required this.topicName,
    required this.level,
    required this.aiRole,
    required this.userRole,
    required this.estimatedMinutes,
    required this.usageCount,
    required this.avgScore,
    required this.isActive,
    required this.keyPhrases,
  });

  AdminScenarioItem copyWith({
    String? id,
    String? title,
    String? topicId,
    String? topicName,
    UserLevel? level,
    String? aiRole,
    String? userRole,
    int? estimatedMinutes,
    int? usageCount,
    double? avgScore,
    bool? isActive,
    List<String>? keyPhrases,
  }) {
    return AdminScenarioItem(
      id: id ?? this.id,
      title: title ?? this.title,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      level: level ?? this.level,
      aiRole: aiRole ?? this.aiRole,
      userRole: userRole ?? this.userRole,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      usageCount: usageCount ?? this.usageCount,
      avgScore: avgScore ?? this.avgScore,
      isActive: isActive ?? this.isActive,
      keyPhrases: keyPhrases ?? this.keyPhrases,
    );
  }
}

/// AI Engine & Telemetry Parameters
class AdminAiConfig {
  final String modelName;
  final double temperature;
  final double bargeInSensitivity;
  final int maxTurnDurationSec;
  final String systemPrompt;
  final String preferredTtsVoice;
  final int monthlyTokenQuota;
  final int monthlyTokensUsed;
  final int activeWebSocketConnections;

  const AdminAiConfig({
    required this.modelName,
    required this.temperature,
    required this.bargeInSensitivity,
    required this.maxTurnDurationSec,
    required this.systemPrompt,
    required this.preferredTtsVoice,
    required this.monthlyTokenQuota,
    required this.monthlyTokensUsed,
    required this.activeWebSocketConnections,
  });

  AdminAiConfig copyWith({
    String? modelName,
    double? temperature,
    double? bargeInSensitivity,
    int? maxTurnDurationSec,
    String? systemPrompt,
    String? preferredTtsVoice,
    int? monthlyTokenQuota,
    int? monthlyTokensUsed,
    int? activeWebSocketConnections,
  }) {
    return AdminAiConfig(
      modelName: modelName ?? this.modelName,
      temperature: temperature ?? this.temperature,
      bargeInSensitivity: bargeInSensitivity ?? this.bargeInSensitivity,
      maxTurnDurationSec: maxTurnDurationSec ?? this.maxTurnDurationSec,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      preferredTtsVoice: preferredTtsVoice ?? this.preferredTtsVoice,
      monthlyTokenQuota: monthlyTokenQuota ?? this.monthlyTokenQuota,
      monthlyTokensUsed: monthlyTokensUsed ?? this.monthlyTokensUsed,
      activeWebSocketConnections: activeWebSocketConnections ?? this.activeWebSocketConnections,
    );
  }
}
