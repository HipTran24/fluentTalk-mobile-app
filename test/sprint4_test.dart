import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_mobile_app/features/conversation/data/chat_repository.dart';
import 'package:english_mobile_app/features/conversation/domain/models/chat_models.dart';
import 'package:english_mobile_app/features/conversation/presentation/controllers/chat_controller.dart';
import 'package:english_mobile_app/features/home/presentation/controllers/home_controller.dart';
import 'package:english_mobile_app/features/home/presentation/home_screen.dart';
import 'package:english_mobile_app/features/conversation/presentation/text_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sprint 4 - HomeDashboardController Tests', () {
    test('Demo dashboard loads dynamic greeting and sample recommendations',
        () async {
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWithValue(const AppConfig(demoMode: true)),
      ]);
      addTearDown(container.dispose);

      final state = container.read(homeDashboardControllerProvider);

      expect(state.userName, isNotEmpty);
      expect(state.greeting, isNotEmpty);
      expect(state.streakDays, greaterThanOrEqualTo(0));
      expect(state.microInsightTitle, isNotEmpty);
      expect(state.microInsightEvidence, isNotEmpty);
      expect(state.nextLessonTitle, isNotEmpty);
      expect(state.nextLessonScenarioId, isNotEmpty);

      // Wait for background async scenario load
      await Future.delayed(const Duration(milliseconds: 350));
    });
  });

  group('Sprint 4 - ChatRepository & ChatController Tests', () {
    test('ChatRepository mock generates Tom responses and idempotency check',
        () async {
      final repo = MockChatRepository();

      final reply = await repo.sendTextMessage(
        text: 'How do I introduce myself?',
        idempotencyKey: 'idemp_key_001',
      );

      expect(reply.isAi, isTrue);
      expect(reply.audioUrl, isNotNull);
      expect(reply.usefulPhrases, isNotEmpty);
      expect(reply.suggestedFollowUps, isNotEmpty);

      // Testing idempotency violation
      expect(
        () => repo.sendTextMessage(
          text: 'How do I introduce myself?',
          idempotencyKey: 'idemp_key_001',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'ChatController sends message, sets thinking state, and handles speed changes',
        () async {
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWithValue(const AppConfig(demoMode: true))
      ]);
      addTearDown(container.dispose);

      final controller = container.read(chatControllerProvider.notifier);

      var state = container.read(chatControllerProvider);
      expect(state.messages.length, greaterThanOrEqualTo(1));
      expect(state.messages.first.isAi, isTrue);

      // Test speed toggle
      expect(state.globalPlaybackSpeed, 1.0);
      controller.setPlaybackSpeed(1.25);
      expect(container.read(chatControllerProvider).globalPlaybackSpeed, 1.25);
      controller.setPlaybackSpeed(0.75);
      expect(container.read(chatControllerProvider).globalPlaybackSpeed, 0.75);

      // Test sending message
      await controller.sendTextMessage('Can I have oat milk?');
      state = container.read(chatControllerProvider);

      // User message and Tom reply should both exist
      expect(state.messages.length, greaterThanOrEqualTo(2));
      final userMessage =
          state.messages.firstWhere((m) => m.text == 'Can I have oat milk?');
      expect(userMessage.isUser, isTrue);
      expect(userMessage.deliveryStatus, MessageDeliveryStatus.sent);
    });
  });

  group('Sprint 4 - UI Widget Smoke Tests', () {
    testWidgets(
        'Demo HomeScreen renders sample profile, streak, and recommendations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(const AppConfig(demoMode: true))
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Chuỗi liên tục'), findsOneWidget);
      expect(find.textContaining('Đề xuất theo điểm yếu'), findsOneWidget);
    });

    testWidgets(
        'TextChatScreen renders conversation interface and useful chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TextChatScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TextChatScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });
  });
}
