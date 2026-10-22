import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/core/network/api_failure.dart';
import 'package:english_mobile_app/features/conversation/data/chat_repository.dart';
import 'package:english_mobile_app/features/conversation/data/remote_chat_repository.dart';
import 'package:english_mobile_app/features/conversation/domain/models/chat_models.dart';
import 'package:english_mobile_app/features/conversation/presentation/controllers/chat_controller.dart';
import 'api_client_test.dart' show ScriptedAdapter, jsonResponse;

const sessionId = '10000000-0000-0000-0000-000000000001';
Map<String, Object?> message() => {
      'id': '10000000-0000-0000-0000-000000000002',
      'role': 'ai',
      'text': 'Hello!',
      'timestamp': '2026-10-22T05:00:00Z',
      'usefulPhrases': <String>[],
      'suggestedFollowUps': <String>[],
    };

class RetryRepository implements ChatRepository {
  final List<String> keys = [];
  final Completer<void>? gate;
  RetryRepository({this.gate});
  @override
  Future<ChatMessage> sendTextMessage(
      {required String text,
      required String idempotencyKey,
      String? userLevel}) async {
    keys.add(idempotencyKey);
    await gate?.future;
    if (keys.length == 1) {
      throw const ApiFailure(code: 'TIMEOUT', message: 'Thử lại');
    }
    return ChatMessage(
        id: 'reply', role: 'ai', text: 'Hello!', timestamp: DateTime.now());
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'creates remote session, persists account pointer and restores exact transcript',
      () async {
    final adapter = ScriptedAdapter((request, _) {
      if (request.path == 'sessions') {
        return jsonResponse({'id': sessionId}, 201);
      }
      if (request.path.endsWith('/messages')) {
        return jsonResponse({'aiMessage': message()});
      }
      return jsonResponse({
        'id': sessionId,
        'status': 'active',
        'messages': [message()]
      });
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test/api/v1'),
        accessToken: () => 'fixture',
        dio: dio);
    addTearDown(api.close);
    final repo = RemoteChatRepository(api, accountId: 'user-a');
    final reply =
        await repo.sendTextMessage(text: 'Hi', idempotencyKey: 'turn-key-0001');
    expect(reply.text, 'Hello!');
    expect(adapter.requests[0].headers['Idempotency-Key'], isNotEmpty);
    expect(adapter.requests[1].headers['Idempotency-Key'], 'turn-key-0001');
    final restored = RemoteChatRepository(api, accountId: 'user-a');
    expect((await restored.loadMessages()).single.text, 'Hello!');
    expect(restored.sessionId, sessionId);
    final otherAccount = RemoteChatRepository(api, accountId: 'user-b');
    expect(await otherAccount.loadMessages(), isEmpty);
    expect(otherAccount.sessionId, isNull);
  });

  test(
      'retry reuses exact key and replaces failed status without another user bubble',
      () async {
    final repo = RetryRepository();
    final controller = ChatController(repo, isDemo: false);
    addTearDown(controller.dispose);
    await controller.sendTextMessage('Hello');
    final failed = controller.state.messages.last;
    expect(failed.deliveryStatus, MessageDeliveryStatus.failed);
    await controller.retryMessage(failed.id);
    expect(repo.keys, [repo.keys.first, repo.keys.first]);
    expect(controller.state.messages.where((m) => m.isUser).length, 1);
    expect(
        controller.state.messages.where((m) => m.isUser).single.deliveryStatus,
        MessageDeliveryStatus.sent);
  });

  test('double tap and disposed controller cannot append another reply',
      () async {
    final gate = Completer<void>();
    final repo = RetryRepository(gate: gate);
    final controller = ChatController(repo);
    final pending = controller.sendTextMessage('Hello');
    await controller.sendTextMessage('Duplicate');
    expect(repo.keys.length, 1);
    controller.dispose();
    gate.complete();
    await pending;
  });

  test('invalid transcript roles are rejected', () {
    expect(
        () =>
            RemoteChatRepository.parseMessage({...message(), 'role': 'admin'}),
        throwsA(isA<ApiFailure>()));
  });
}
