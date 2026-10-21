import 'enums.dart';

/// User Profile Entity
/// Compliant with ESP-PLAN-001 Section 5 and Appendix A1-A6
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final UserLevel level;
  final LearningGoalType goal;
  final int dailyMinutes;
  final int currentStreak;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.level = UserLevel.a1,
    this.goal = LearningGoalType.daily,
    this.dailyMinutes = 15,
    this.currentStreak = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Learner',
      avatarUrl: json['avatar_url'] as String?,
      level: UserLevel.fromString(json['level'] as String?),
      goal: LearningGoalType.values.firstWhere(
        (g) => g.name == json['goal'],
        orElse: () => LearningGoalType.daily,
      ),
      dailyMinutes: json['daily_minutes'] as int? ?? 15,
      currentStreak: json['current_streak'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'level': level.code,
      'goal': goal.name,
      'daily_minutes': dailyMinutes,
      'current_streak': currentStreak,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    UserLevel? level,
    LearningGoalType? goal,
    int? dailyMinutes,
    int? currentStreak,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      goal: goal ?? this.goal,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// User Privacy and System Settings
class UserSettings {
  final String userId;
  final bool notificationsEnabled;
  final bool saveAudioConsent;
  final int audioRetentionDays;
  final String preferredVoice;
  final double speakingSpeed;
  final bool liveCaptionsEnabled;

  const UserSettings({
    required this.userId,
    this.notificationsEnabled = true,
    this.saveAudioConsent = false,
    this.audioRetentionDays = 30,
    this.preferredVoice = 'en-US-Journey-F',
    this.speakingSpeed = 1.0,
    this.liveCaptionsEnabled = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      saveAudioConsent: json['save_audio'] as bool? ?? false,
      audioRetentionDays: json['retention_days'] as int? ?? 30,
      preferredVoice: json['preferred_voice'] as String? ?? 'en-US-Journey-F',
      speakingSpeed: (json['speaking_speed'] as num?)?.toDouble() ?? 1.0,
      liveCaptionsEnabled: json['live_captions'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'notifications_enabled': notificationsEnabled,
      'save_audio': saveAudioConsent,
      'retention_days': audioRetentionDays,
      'preferred_voice': preferredVoice,
      'speaking_speed': speakingSpeed,
      'live_captions': liveCaptionsEnabled,
    };
  }
}
