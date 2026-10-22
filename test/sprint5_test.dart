import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_mobile_app/features/conversation/data/guided_repository.dart';
import 'package:english_mobile_app/features/conversation/domain/models/guided_models.dart';
import 'package:english_mobile_app/features/conversation/presentation/controllers/guided_controller.dart';
import 'package:english_mobile_app/features/conversation/presentation/guided_speaking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sprint 5 - GuidedSpeakingRepository Tests', () {
    test('Loads turns for sc_travel_01 and sc_intro_01', () async {
      final repo = MockGuidedSpeakingRepository();
      final turns = await repo.getTurnsForScenario('sc_travel_01');
      expect(turns.length, 4);
      expect(turns.first.turnIndex, 1);
      expect(turns.first.aiPromptEn, contains('Bella Italia'));
      expect(turns.first.suggestedStarters, isNotEmpty);
      expect(turns.first.keyVocabulary, isNotEmpty);

      final introTurns = await repo.getTurnsForScenario('sc_intro_01');
      expect(introTurns.length, 3);
      expect(introTurns.first.aiPromptEn, contains('Sarah'));
    });

    test('Transcribes audio and evaluates turn with rubric feedback', () async {
      final repo = MockGuidedSpeakingRepository();
      final transcript =
          await repo.transcribeAudio(scenarioId: 'sc_travel_01', turnIndex: 1);
      expect(transcript, contains('table for two'));

      final feedback = await repo.evaluateTurn(
        scenarioId: 'sc_travel_01',
        turnIndex: 1,
        userTranscript: transcript,
      );
      expect(feedback.score, greaterThanOrEqualTo(80));
      expect(feedback.praise, isNotEmpty);
      expect(feedback.nativeAlternative, isNotNull);
      expect(feedback.usedKeywords, isNotEmpty);
    });
  });

  group('Sprint 5 - GuidedSpeakingController Tests', () {
    test('Initializes session, handles recording lifecycle, and speed toggle',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container
          .read(guidedSpeakingControllerProvider('sc_travel_01').notifier);
      // Wait for repository fetch
      await controller.loadSession();

      var state =
          container.read(guidedSpeakingControllerProvider('sc_travel_01'));
      expect(state.isLoading, isFalse);
      expect(state.turns.length, 4);
      expect(state.currentTurnIndex, 0);
      expect(state.recordingState, RecordingState.idle);

      // Speech rate test
      expect(state.aiSpeechRate, 1.0);
      controller.setAiSpeechRate(0.75);
      expect(
          container
              .read(guidedSpeakingControllerProvider('sc_travel_01'))
              .aiSpeechRate,
          0.75);

      // Translation toggle test
      expect(state.showAiTranslation, isFalse);
      controller.toggleTranslation();
      expect(
          container
              .read(guidedSpeakingControllerProvider('sc_travel_01'))
              .showAiTranslation,
          isTrue);

      // Recording lifecycle
      controller.startRecording();
      state = container.read(guidedSpeakingControllerProvider('sc_travel_01'));
      expect(state.recordingState, RecordingState.recording);

      // Stop recording -> transcribing -> reviewing
      await controller.stopRecording();
      state = container.read(guidedSpeakingControllerProvider('sc_travel_01'));
      expect(state.recordingState, RecordingState.reviewing);
      expect(state.currentTranscriptDraft, isNotEmpty);

      // Edit draft transcript
      controller.updateTranscriptDraft('Good evening! Table for two please.');
      expect(
        container
            .read(guidedSpeakingControllerProvider('sc_travel_01'))
            .currentTranscriptDraft,
        'Good evening! Table for two please.',
      );

      // Submit turn for evaluation
      await controller.submitTurn();
      state = container.read(guidedSpeakingControllerProvider('sc_travel_01'));
      expect(state.latestFeedback, isNotNull);
      expect(state.latestFeedback!.score, greaterThan(0));
      expect(state.turns[0].isCompleted, isTrue);

      // Next turn
      await controller.nextTurn();
      state = container.read(guidedSpeakingControllerProvider('sc_travel_01'));
      expect(state.currentTurnIndex, 1);
      expect(state.latestFeedback, isNull);
    });
  });

  group('Sprint 5 - UI Widget Smoke Tests', () {
    testWidgets(
        'GuidedSpeakingScreen renders turn header, Tom card, and recording button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GuidedSpeakingScreen(scenarioId: 'sc_travel_01'),
          ),
        ),
      );

      // Wait for async initialization
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidedSpeakingScreen), findsOneWidget);
      expect(find.textContaining('Lượt 1/4'), findsOneWidget);
      expect(find.textContaining('Tom: Bồi bàn'), findsOneWidget);
      expect(find.textContaining('Bella Italia'), findsOneWidget);
      expect(find.textContaining('Mục tiêu lượt nói của bạn:'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });
  });
}
