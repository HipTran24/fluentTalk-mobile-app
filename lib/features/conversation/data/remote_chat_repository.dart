import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../domain/models/chat_models.dart';
import 'chat_repository.dart';

/// Persistent sessions belong to a single authenticated account.
class RemoteChatRepository implements ChatRepository {
  final ApiClient? client;
  final String accountId;
  String? sessionId;
  String? scenarioId;
  String level;
  String _createKey = ApiClient.newIdempotencyKey();

  RemoteChatRepository(this.client,
      {required this.accountId, this.level = 'A1'});

  ApiClient get _api =>
      client ??
      (throw const ApiFailure(
        code: 'CONFIGURATION_REQUIRED',
        message: 'Chưa cấu hình máy chủ học tập.',
      ));

  String get _storageKey => 'chat_session_$accountId';

  Future<List<ChatMessage>> loadMessages() async {
    if (accountId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    sessionId = prefs.getString(_storageKey);
    if (sessionId == null) return [];
    try {
      final json = _object(await _api.get('sessions/$sessionId'));
      if (json['status'] != 'active') {
        sessionId = null;
        await prefs.remove(_storageKey);
        return [];
      }
      final messages = json['messages'];
      if (messages is! List) throw _invalid();
      return messages.map((item) => parseMessage(_object(item))).toList();
    } on ApiFailure catch (e) {
      if (e.statusCode != 404) rethrow;
      sessionId = null;
      await prefs.remove(_storageKey);
      return [];
    }
  }

  @override
  Future<ChatMessage> sendTextMessage(
      {required String text,
      required String idempotencyKey,
      String? userLevel}) async {
    if (sessionId == null) {
      final session = _object(await _api.post('sessions',
          data: {
            'mode': 'text',
            'level': userLevel ?? level,
            if (scenarioId != null) 'scenarioId': scenarioId
          },
          idempotencyKey: _createKey));
      final id = session['id'];
      if (id is! String || !_uuid.hasMatch(id)) throw _invalid();
      sessionId = id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, id);
    }
    final turn = _object(await _api.post('sessions/$sessionId/messages',
        data: {'text': text}, idempotencyKey: idempotencyKey));
    final reply = parseMessage(_object(turn['aiMessage']));
    if (!reply.isAi) throw _invalid();
    return reply;
  }

  Future<void> completeSession() async {
    if (sessionId == null) return;
    await _api.post('sessions/$sessionId/complete',
        idempotencyKey: 'complete_${sessionId!}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    sessionId = null;
    _createKey = ApiClient.newIdempotencyKey();
  }

  static final _uuid = RegExp(
      r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$');

  static ApiFailure _invalid() => const ApiFailure(
      code: 'INVALID_RESPONSE', message: 'Dữ liệu hội thoại chưa hợp lệ.');
  static Map<String, dynamic> _object(Object? json) {
    if (json is! Map<String, dynamic>) throw _invalid();
    return json;
  }

  static ChatMessage parseMessage(Map<String, dynamic> json) {
    final id = json['id'];
    final role = json['role'];
    final text = json['text'];
    final time = json['timestamp'];
    if (id is! String ||
        !_uuid.hasMatch(id) ||
        !['ai', 'user'].contains(role) ||
        text is! String ||
        time is! String ||
        DateTime.tryParse(time) == null) {
      throw _invalid();
    }
    List<String> strings(String key) {
      final value = json[key];
      if (value == null) return [];
      if (value is! List || value.any((e) => e is! String)) throw _invalid();
      return value.cast<String>();
    }

    return ChatMessage(
        id: id,
        role: role as String,
        text: text,
        timestamp: DateTime.parse(time).toLocal(),
        usefulPhrases: strings('usefulPhrases'),
        suggestedFollowUps: strings('suggestedFollowUps'));
  }
}
