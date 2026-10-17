import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_mobile_app/features/coach/data/coach_repository.dart';
import 'package:english_mobile_app/features/coach/presentation/controllers/coach_controller.dart';
import 'package:english_mobile_app/features/coach/presentation/coach_screen.dart';
import 'package:english_mobile_app/features/coach/presentation/drill_player_screen.dart';
import 'package:english_mobile_app/features/coach/presentation/weekly_plan_screen.dart';
import 'package:english_mobile_app/features/profile/data/profile_repository.dart';
import 'package:english_mobile_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:english_mobile_app/features/profile/presentation/vocabulary_screen.dart';
import 'package:english_mobile_app/features/profile/presentation/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sprint 8 - CoachRepository & DrillController Tests', () {
    test('Loads 3 prioritized weaknesses with speech evidence', () async {
      final repo = MockCoachRepository();
      final weaknesses = await repo.getIdentifiedWeaknesses();

      expect(weaknesses.length, 3);
      expect(weaknesses.first.evidence, isNotEmpty);
      expect(weaknesses.first.recurrenceCount, greaterThan(0));

      final drill = await repo.getDrillById('drill_past_tense');
      expect(drill.targetPhrase, contains('supermarket'));

      final plan = await repo.getWeeklyPlan();
      expect(plan.length, 7);
      expect(plan.any((p) => p.isToday), isTrue);
    });

    test('DrillPlayerController manages steps, recording and completion', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(drillPlayerControllerProvider('drill_past_tense').notifier);
      await controller.loadDrill();

      var state = container.read(drillPlayerControllerProvider('drill_past_tense'));
      expect(state.isLoading, isFalse);
      expect(state.currentStep, 1);
      expect(state.totalSteps, 3);

      controller.startRecording();
      state = container.read(drillPlayerControllerProvider('drill_past_tense'));
      expect(state.isRecording, isTrue);

      await controller.stopRecording();
      state = container.read(drillPlayerControllerProvider('drill_past_tense'));
      expect(state.isRecording, isFalse);
      expect(state.hasResult, isTrue);
      expect(state.score, 95.0);

      // Advance to step 2, step 3, and complete
      controller.nextStep();
      expect(container.read(drillPlayerControllerProvider('drill_past_tense')).currentStep, 2);

      controller.nextStep();
      expect(container.read(drillPlayerControllerProvider('drill_past_tense')).currentStep, 3);

      controller.nextStep();
      expect(container.read(drillPlayerControllerProvider('drill_past_tense')).isCompleted, isTrue);
    });
  });

  group('Sprint 8 - ProfileRepository & Controller Tests', () {
    test('Loads vocabulary and toggles mastered status', () async {
      final repo = MockProfileRepository();
      final words = await repo.getSavedVocabulary();
      expect(words.length, greaterThanOrEqualTo(3));

      final initialMastered = words.first.isMastered;
      final toggled = await repo.toggleMastered(words.first.id);
      expect(toggled, !initialMastered);
    });

    test('ProfileSettingsController updates preferences and speed', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(profileSettingsControllerProvider.notifier);
      var state = container.read(profileSettingsControllerProvider);

      expect(state.defaultSpeed, 1.0);
      controller.setDefaultSpeed(1.25);
      expect(container.read(profileSettingsControllerProvider).defaultSpeed, 1.25);

      expect(state.notifications, isTrue);
      controller.setNotifications(false);
      expect(container.read(profileSettingsControllerProvider).notifications, isFalse);

      expect(state.audioConsent, isFalse);
      controller.setAudioConsent(true);
      expect(container.read(profileSettingsControllerProvider).audioConsent, isTrue);
    });
  });

  group('Sprint 8 - UI Widget Smoke Tests', () {
    testWidgets('CoachScreen (Screen 16) renders insights and 3 weaknesses', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CoachScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CoachScreen), findsOneWidget);
      expect(find.textContaining('Coach Emma (Trí nhớ dài hạn)'), findsOneWidget);
      expect(find.textContaining('3 Trọng tâm tuần này của bạn'), findsOneWidget);
      expect(find.textContaining('Vì sao AI đề xuất các bài học này?'), findsOneWidget);
    });

    testWidgets('DrillPlayerScreen (Screen 17) renders step progress and target card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DrillPlayerScreen(drillId: 'drill_past_tense')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DrillPlayerScreen), findsOneWidget);
      expect(find.textContaining('Bài tập sửa lỗi (1/3)'), findsOneWidget);
      expect(find.textContaining('Nghe và nói lại câu chuẩn bản xứ:'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('WeeklyPlanScreen (Screen 18) renders 7-day plan with today badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WeeklyPlanScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(WeeklyPlanScreen), findsOneWidget);
      expect(find.text('Thứ Hai'), findsOneWidget);
      expect(find.text('Thứ Ba'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);
    });

    testWidgets('VocabularyScreen (Screen 19) renders filters and saved words', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: VocabularyScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(VocabularyScreen), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Cần ôn luyện'), findsOneWidget);
      expect(find.text('Đã thành thạo'), findsOneWidget);
      expect(find.textContaining('Could I have the bill, please?'), findsOneWidget);
    });

    testWidgets('ProfileScreen (Screen 20) renders identity card and privacy settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.textContaining('Sổ tay từ vựng & Mẫu câu'), findsOneWidget);
      expect(find.textContaining('Cấu hình gia sư AI & Âm thanh'), findsOneWidget);
      expect(find.textContaining('Lưu trữ file ghi âm (Audio Consent)'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    });
  });
}
