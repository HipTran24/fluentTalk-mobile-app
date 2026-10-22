import '../../../../core/models/enums.dart';
import '../../../../core/models/user_profile.dart';

/// Explicit DTO mapping for backend /me API contract.
/// Contract defines camelCase fields: id, displayName, level, dailyMinutes, onboarded, createdAt.
class MeProfileDto {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String level;
  final String? goal;
  final int dailyMinutes;
  final bool? onboarded;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MeProfileDto({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.level,
    this.goal,
    required this.dailyMinutes,
    this.onboarded,
    required this.createdAt,
    this.updatedAt,
  });

  factory MeProfileDto.fromJson(Map<String, dynamic> json) {
    return MeProfileDto(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName:
          (json['displayName'] ?? json['display_name']) as String? ?? 'Learner',
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      level: json['level'] as String? ?? 'A1',
      goal: json['goal'] as String?,
      dailyMinutes:
          (json['dailyMinutes'] ?? json['daily_minutes']) as int? ?? 15,
      onboarded: json['onboarded'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null),
    );
  }

  UserProfile toDomain() {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      level: UserLevel.fromString(level),
      goal: LearningGoalType.values.firstWhere(
        (g) => g.name == goal,
        orElse: () => LearningGoalType.daily,
      ),
      dailyMinutes: dailyMinutes,
      currentStreak: 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
