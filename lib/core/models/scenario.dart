import 'enums.dart';

/// Topic Category Entity
class Topic {
  final String id;
  final String slug;
  final String title;
  final String icon;
  final bool active;

  const Topic({
    required this.id,
    required this.slug,
    required this.title,
    required this.icon,
    this.active = true,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String? ?? 'topic',
      active: json['active'] as bool? ?? true,
    );
  }
}

/// Vocabulary preview item for Scenario Detail
class VocabularyPreviewItem {
  final String phrase;
  final String ipa;
  final String meaningVi;

  const VocabularyPreviewItem({
    required this.phrase,
    required this.ipa,
    required this.meaningVi,
  });
}

/// Scenario / Kịch bản luyện giao tiếp
class Scenario {
  final String id;
  final String topicId;
  final UserLevel level;
  final String title;
  final String description;
  final String roleAi;
  final String roleUser;
  final List<String> learningObjectives;
  final List<String> samplePhrases;
  final List<VocabularyPreviewItem> vocabularyPreview;
  final int estimatedMinutes;
  final bool isBookmarked;
  final bool active;

  const Scenario({
    required this.id,
    required this.topicId,
    required this.level,
    required this.title,
    required this.description,
    required this.roleAi,
    required this.roleUser,
    required this.learningObjectives,
    this.samplePhrases = const [],
    this.vocabularyPreview = const [],
    this.estimatedMinutes = 5,
    this.isBookmarked = false,
    this.active = true,
  });

  Scenario copyWith({
    String? id,
    String? topicId,
    UserLevel? level,
    String? title,
    String? description,
    String? roleAi,
    String? roleUser,
    List<String>? learningObjectives,
    List<String>? samplePhrases,
    List<VocabularyPreviewItem>? vocabularyPreview,
    int? estimatedMinutes,
    bool? isBookmarked,
    bool? active,
  }) {
    return Scenario(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      level: level ?? this.level,
      title: title ?? this.title,
      description: description ?? this.description,
      roleAi: roleAi ?? this.roleAi,
      roleUser: roleUser ?? this.roleUser,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      samplePhrases: samplePhrases ?? this.samplePhrases,
      vocabularyPreview: vocabularyPreview ?? this.vocabularyPreview,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      active: active ?? this.active,
    );
  }

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      level: UserLevel.fromString(json['level'] as String?),
      title: json['title'] as String,
      description: json['description'] as String,
      roleAi: json['role_ai'] as String,
      roleUser: json['role_user'] as String? ?? 'Learner',
      learningObjectives: (json['learning_objectives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      samplePhrases: (json['sample_phrases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vocabularyPreview: [],
      estimatedMinutes: json['estimated_minutes'] as int? ?? 5,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
    );
  }
}
