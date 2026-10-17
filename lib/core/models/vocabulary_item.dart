/// Saved Vocabulary / Expression item
class VocabularyItem {
  final String id;
  final String phrase;
  final String? ipa;
  final String meaningVi;
  final String exampleSentence;
  final String? sourceScenarioTitle;
  final bool isMastered;
  final DateTime createdAt;

  const VocabularyItem({
    required this.id,
    required this.phrase,
    this.ipa,
    required this.meaningVi,
    required this.exampleSentence,
    this.sourceScenarioTitle,
    this.isMastered = false,
    required this.createdAt,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      phrase: json['phrase'] as String,
      ipa: json['ipa'] as String?,
      meaningVi: json['meaning_vi'] as String,
      exampleSentence: json['example'] as String? ?? '',
      sourceScenarioTitle: json['source_scenario_title'] as String?,
      isMastered: json['mastered'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
