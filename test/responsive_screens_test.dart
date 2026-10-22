import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:english_mobile_app/core/theme/app_theme.dart';
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
  setUpAll(() async {
    final font = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await font.load();
    await icons.load();
  });
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
    'ScenarioDetailScreen':
        const ScenarioDetailScreen(scenarioId: 'sc_travel_01'),
    'TextChatScreen': const TextChatScreen(),
    'GuidedSpeakingScreen':
        const GuidedSpeakingScreen(scenarioId: 'sc_travel_01'),
    'RealtimeCallScreen': const RealtimeCallScreen(sessionId: 'test-session'),
    'SessionSummaryScreen':
        const SessionSummaryScreen(sessionId: 'test-session'),
    'ProgressScreen': const ProgressScreen(),
    'HistoryScreen': const HistoryScreen(),
    'CoachScreen': const CoachScreen(),
    'DrillPlayerScreen': const DrillPlayerScreen(drillId: 'drill_past_tense'),
    'WeeklyPlanScreen': const WeeklyPlanScreen(),
    'VocabularyScreen': const VocabularyScreen(),
    'ProfileScreen': const ProfileScreen(),
  };
  for (final variant in [
    (320.0, 800.0, 2.0),
    (390.0, 844.0, 1.0),
    (768.0, 1024.0, 1.3)
  ]) {
    for (final entry in screens.entries) {
      testWidgets(
          '${entry.key} fits ${variant.$1}dp at ${variant.$3} text scale',
          (tester) async {
        tester.view.physicalSize = Size(variant.$1, variant.$2);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final originalErrorHandler = FlutterError.onError!;
        FlutterError.onError = (details) {
          debugPrint(details.toString());
          originalErrorHandler(details);
        };
        await tester.pumpWidget(ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(const AppConfig(demoMode: true))
          ],
          child: RepaintBoundary(
              key: const ValueKey('screen-capture'),
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(variant.$3)),
                  child: child!,
                ),
                home: entry.value,
              )),
        ));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_UI') && variant.$1 != 768) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('screen-capture')));
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                'docs/qa/ui/${entry.key}-${variant.$1.toInt()}-${(variant.$3 * 100).toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
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
}
