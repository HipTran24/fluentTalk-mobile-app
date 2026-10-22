import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:english_mobile_app/features/auth/presentation/welcome_screen.dart';
import 'package:english_mobile_app/features/auth/presentation/auth_screen.dart';
import 'package:english_mobile_app/features/auth/presentation/learning_unavailable_screen.dart';
import 'package:english_mobile_app/features/onboarding/presentation/goal_onboarding_screen.dart';
import 'package:english_mobile_app/features/onboarding/presentation/placement_screen.dart';
import 'package:english_mobile_app/features/home/presentation/home_screen.dart';
import 'package:english_mobile_app/features/scenarios/presentation/practice_hub_screen.dart';
import 'package:english_mobile_app/features/scenarios/presentation/scenario_catalog_screen.dart';
import 'package:english_mobile_app/features/scenarios/presentation/scenario_detail_screen.dart';
import 'package:english_mobile_app/features/conversation/presentation/text_chat_screen.dart';
import 'package:english_mobile_app/features/conversation/presentation/guided_speaking_screen.dart';
import 'package:english_mobile_app/features/conversation/presentation/realtime_call_screen.dart';
import 'package:english_mobile_app/features/feedback/presentation/session_summary_screen.dart';
import 'package:english_mobile_app/features/progress/presentation/progress_screen.dart';
import 'package:english_mobile_app/features/progress/presentation/history_screen.dart';
import 'package:english_mobile_app/features/coach/presentation/coach_screen.dart';
import 'package:english_mobile_app/features/coach/presentation/drill_player_screen.dart';
import 'package:english_mobile_app/features/coach/presentation/weekly_plan_screen.dart';
import 'package:english_mobile_app/features/profile/presentation/vocabulary_screen.dart';
import 'package:english_mobile_app/features/profile/presentation/profile_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final screens = <String, Widget>{
    'WelcomeScreen': const WelcomeScreen(),
    'AuthScreen': const AuthScreen(),
    'LearningUnavailableScreen': const LearningUnavailableScreen(),
    'GoalOnboardingScreen': const GoalOnboardingScreen(),
    'PlacementScreen': const PlacementScreen(),
    'HomeScreen': const HomeScreen(),
    'PracticeHubScreen': const PracticeHubScreen(),
    'ScenarioCatalogScreen': const ScenarioCatalogScreen(),
    'ScenarioDetailScreen': const ScenarioDetailScreen(scenarioId: 'sc_travel_01'),
    'TextChatScreen': const TextChatScreen(),
    'GuidedSpeakingScreen': const GuidedSpeakingScreen(scenarioId: 'sc_travel_01'),
    'RealtimeCallScreen': const RealtimeCallScreen(sessionId: 'test-session'),
    'SessionSummaryScreen': const SessionSummaryScreen(sessionId: 'test-session'),
    'ProgressScreen': const ProgressScreen(),
    'HistoryScreen': const HistoryScreen(),
    'CoachScreen': const CoachScreen(),
    'DrillPlayerScreen': const DrillPlayerScreen(drillId: 'drill_past_tense'),
    'WeeklyPlanScreen': const WeeklyPlanScreen(),
    'VocabularyScreen': const VocabularyScreen(),
    'ProfileScreen': const ProfileScreen(),
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} fits 320dp at 200 percent text', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(demoMode: true))],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: entry.value,
        ),
      ));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      // Force lazy list children through layout as well.
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
