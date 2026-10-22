import '../../../core/models/enums.dart';
import '../../../core/models/scenario.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import 'scenario_repository.dart';

/// Public catalog metadata. Never substitutes demo content on API failure.
class RemoteScenarioRepository extends ScenarioRepository {
  final ApiClient? _client;

  RemoteScenarioRepository(this._client);

  @override
  bool get supportsBookmarks => false;
  @override
  bool get supportsCuratedTabs => false;

  ApiClient get _api =>
      _client ??
      (throw const ApiFailure(
        code: 'CONFIGURATION_REQUIRED',
        message: 'Chưa cấu hình máy chủ để tải danh mục học.',
      ));

  @override
  Future<List<Topic>> getTopics() async {
    final data = await _api.get('topics', authenticated: false);
    if (data is! List) throw _invalidResponse;
    return List.unmodifiable(data.map((item) {
      final json = _object(item, allowed: const {'id', 'slug', 'title'});
      final slug = _text(json, 'slug');
      return Topic(
        id: _id(json, 'id'),
        slug: slug,
        title: _text(json, 'title'),
        icon: switch (slug) {
          'introduction' || 'intro' => '👋',
          'daily-life' || 'daily' => '☕',
          'travel' => '✈️',
          'work' || 'career' => '💼',
          _ => '📚',
        },
      );
    }));
  }

  @override
  Future<List<Scenario>> getScenarios({
    String? topicId,
    UserLevel? level,
    String? searchQuery,
    String? filterTab,
  }) async =>
      (await getScenarioPage(
        topicId: topicId,
        level: level,
        searchQuery: searchQuery,
        filterTab: filterTab,
      ))
          .items;

  @override
  Future<ScenarioPage> getScenarioPage({
    String? topicId,
    UserLevel? level,
    String? searchQuery,
    String? filterTab,
    int page = 0,
    int size = 20,
  }) async {
    final query = searchQuery?.trim() ?? '';
    if (page < 0 || size < 1 || size > 100 || query.runes.length > 100) {
      throw const ApiFailure(
        code: 'VALIDATION_ERROR',
        message: 'Bộ lọc hoặc trang danh mục chưa hợp lệ.',
      );
    }
    if (filterTab != null && filterTab != 'all') {
      throw const ApiFailure(
        code: 'FEATURE_UNAVAILABLE',
        message: 'Bộ lọc này chưa được hỗ trợ trên máy chủ.',
      );
    }
    if (topicId != null && topicId != 'all' && !_uuid.hasMatch(topicId)) {
      throw const ApiFailure(
          code: 'VALIDATION_ERROR', message: 'Chủ đề chưa hợp lệ.');
    }
    final data = _object(
        await _api.get('scenarios', authenticated: false, query: {
          'page': page,
          'size': size,
          if (topicId != null && topicId != 'all') 'topic': topicId,
          if (level != null) 'level': level.code,
          if (query.isNotEmpty) 'q': query,
        }),
        allowed: const {'items', 'page', 'size', 'hasMore'});
    final items = data['items'];
    final hasMore = data['hasMore'];
    if (items is! List ||
        items.length > size ||
        data['page'] is! int ||
        data['size'] is! int ||
        data['page'] != page ||
        data['size'] != size ||
        hasMore is! bool ||
        (hasMore && items.isEmpty)) {
      throw _invalidResponse;
    }
    return ScenarioPage(
      items: List.unmodifiable(items.map(_scenario)),
      page: page,
      size: size,
      hasMore: hasMore,
    );
  }

  @override
  Future<Scenario?> getScenarioById(String id) async {
    if (!_uuid.hasMatch(id)) return null;
    try {
      final scenario =
          _scenario(await _api.get('scenarios/$id', authenticated: false));
      if (scenario.id.toLowerCase() != id.toLowerCase()) throw _invalidResponse;
      return scenario;
    } on ApiFailure catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<bool> toggleBookmark(String scenarioId) async =>
      throw const ApiFailure(
        code: 'FEATURE_UNAVAILABLE',
        message: 'Lưu tình huống chưa được hỗ trợ trên máy chủ.',
      );
}

const _invalidResponse = ApiFailure(
  code: 'INVALID_RESPONSE',
  message: 'Dữ liệu danh mục chưa hợp lệ. Hãy thử tải lại.',
  canRetry: true,
);
final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

Map<String, dynamic> _object(Object? value, {Set<String>? allowed}) {
  if (value is! Map<String, dynamic>) throw _invalidResponse;
  if (allowed != null && value.keys.any((key) => !allowed.contains(key))) {
    throw _invalidResponse;
  }
  return value;
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) throw _invalidResponse;
  return value;
}

String _id(Map<String, dynamic> json, String key) {
  final value = _text(json, key);
  if (!_uuid.hasMatch(value)) throw _invalidResponse;
  return value;
}

List<String> _strings(Map<String, dynamic> json, String key,
    {bool optional = false}) {
  final value = json[key];
  if (optional && !json.containsKey(key)) return const [];
  if (value is! List || value.any((item) => item is! String)) {
    throw _invalidResponse;
  }
  return List<String>.unmodifiable(value.cast<String>());
}

Scenario _scenario(Object? value) {
  final json = _object(value, allowed: const {
    'id',
    'topicId',
    'level',
    'title',
    'description',
    'roleAi',
    'roleUser',
    'learningObjectives',
    'estimatedMinutes',
    'samplePhrases',
    'vocabularyPreview',
    'active',
  });
  final level = json['level'];
  final matchingLevels = UserLevel.values.where((item) => item.code == level);
  final minutes = json['estimatedMinutes'];
  final vocabulary = json.containsKey('vocabularyPreview')
      ? json['vocabularyPreview']
      : const [];
  final active = json.containsKey('active') ? json['active'] : true;
  if (matchingLevels.isEmpty ||
      minutes is! int ||
      minutes < 1 ||
      vocabulary is! List ||
      active != true) {
    throw _invalidResponse;
  }
  return Scenario(
    id: _id(json, 'id'),
    topicId: _id(json, 'topicId'),
    level: matchingLevels.single,
    title: _text(json, 'title'),
    description: _text(json, 'description'),
    roleAi: _text(json, 'roleAi'),
    roleUser: _text(json, 'roleUser'),
    learningObjectives: _strings(json, 'learningObjectives'),
    estimatedMinutes: minutes,
    samplePhrases: _strings(json, 'samplePhrases', optional: true),
    vocabularyPreview: List.unmodifiable(vocabulary.map((item) {
      final row = _object(item, allowed: const {'phrase', 'ipa', 'meaningVi'});
      final ipa = row['ipa'];
      if (ipa != null && ipa is! String) throw _invalidResponse;
      return VocabularyPreviewItem(
        phrase: _text(row, 'phrase'),
        ipa: ipa as String? ?? '',
        meaningVi: _text(row, 'meaningVi'),
      );
    })),
  );
}
