import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_mobile_app/features/conversation/data/realtime_repository.dart';
import 'package:english_mobile_app/features/conversation/domain/models/realtime_models.dart';
import 'package:english_mobile_app/features/conversation/presentation/controllers/realtime_controller.dart';
import 'package:english_mobile_app/features/conversation/presentation/realtime_call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sprint 6 - RealtimeCallRepository Tests', () {
    test('Loads topic hints and initial conversation', () async {
      final repo = MockRealtimeCallRepository();
      final hints = await repo.getTopicHints('sess_rt_01');
      expect(hints.length, greaterThanOrEqualTo(3));
      expect(hints.first.englishPhrase, isNotEmpty);
      expect(hints.first.vietnameseMeaning, isNotEmpty);

      final initialCaps = await repo.getInitialConversation('sess_rt_01');
      expect(initialCaps.length, 1);
      expect(initialCaps.first.isAi, isTrue);
      expect(initialCaps.first.text, contains('Emma'));
    });
  });

  group('Sprint 6 - RealtimeCallController Tests', () {
    test('Handles call lifecycle, controls, barge-in interrupt, and termination', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(realtimeCallControllerProvider('sess_rt_01').notifier);
      await controller.initCall();

      var state = container.read(realtimeCallControllerProvider('sess_rt_01'));
      expect(state.speakerState, RealtimeSpeakerState.aiSpeaking);
      expect(state.captionsHistory.length, 1);
      expect(state.formattedDuration, isNotEmpty);

      // Controls test: Mute, Speakerphone, Captions
      expect(state.isMuted, isFalse);
      controller.toggleMute();
      expect(container.read(realtimeCallControllerProvider('sess_rt_01')).isMuted, isTrue);

      expect(state.isSpeakerPhoneOn, isTrue);
      controller.toggleSpeakerPhone();
      expect(container.read(realtimeCallControllerProvider('sess_rt_01')).isSpeakerPhoneOn, isFalse);

      expect(state.showCaptions, isTrue);
      controller.toggleCaptions();
      expect(container.read(realtimeCallControllerProvider('sess_rt_01')).showCaptions, isFalse);

      // Barge-in Interrupt Test: When AI is speaking, user interrupts
      state = container.read(realtimeCallControllerProvider('sess_rt_01'));
      if (state.speakerState == RealtimeSpeakerState.aiSpeaking) {
        controller.interruptAi();
        expect(
          container.read(realtimeCallControllerProvider('sess_rt_01')).speakerState,
          RealtimeSpeakerState.listening,
        );
      }

      // Simulate User Speech
      controller.toggleMute(); // Unmute first
      controller.simulateUserSpeech('I had a fantastic meeting with my new client today!');
      state = container.read(realtimeCallControllerProvider('sess_rt_01'));
      expect(state.speakerState, RealtimeSpeakerState.userSpeaking);
      expect(state.captionsHistory.length, 2);

      // End Call
      await controller.endCall();
      state = container.read(realtimeCallControllerProvider('sess_rt_01'));
      expect(state.speakerState, RealtimeSpeakerState.ended);
      expect(state.isCallEnded, isTrue);
    });
  });

  group('Sprint 6 - UI Widget Smoke Tests', () {
    testWidgets('RealtimeCallScreen renders status bar, avatar, captions, and controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RealtimeCallScreen(sessionId: 'sess_rt_01'),
          ),
        ),
      );

      // Wait for animation frame
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(RealtimeCallScreen), findsOneWidget);
      expect(find.textContaining('Trực tiếp'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
      expect(find.byIcon(Icons.subtitles_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    });
  });
}
