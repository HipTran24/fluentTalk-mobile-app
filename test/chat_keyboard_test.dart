import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:english_mobile_app/features/conversation/data/chat_repository.dart';
import 'package:english_mobile_app/features/conversation/domain/models/chat_models.dart';
import 'package:english_mobile_app/features/conversation/presentation/controllers/chat_controller.dart';
import 'package:english_mobile_app/features/conversation/presentation/text_chat_screen.dart';

class RichReplyRepository implements ChatRepository {
  @override
  Future<ChatMessage> sendTextMessage(
          {required String text,
          required String idempotencyKey,
          String? userLevel}) async =>
      ChatMessage(
          id: 'rich-reply',
          role: 'ai',
          text:
              'Could you tell me a little more about your work and the hobbies you enjoy in your free time?',
          timestamp: DateTime(2026),
          usefulPhrases: [
            'I would be delighted to introduce myself to the entire team.'
          ],
          suggestedFollowUps: [
            'Can you explain this expression in Vietnamese with a practical example?'
          ]);
}

void main() {
  testWidgets(
      'chat rich reply and composer fit enlarged text with keyboard visible',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig(demoMode: true)),
          chatRepositoryProvider.overrideWithValue(RichReplyRepository()),
        ],
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const TextChatScreen())));
    await tester.enterText(
        find.byType(TextField), 'How can I introduce myself?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byIcon(Icons.send_rounded)).bottom,
        lessThanOrEqualTo(480));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
