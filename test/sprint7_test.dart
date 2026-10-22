import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_mobile_app/core/models/enums.dart';
import 'package:english_mobile_app/features/feedback/data/feedback_repository.dart';
import 'package:english_mobile_app/features/feedback/presentation/session_summary_screen.dart';
import 'package:english_mobile_app/features/progress/presentation/controllers/progress_controller.dart';
import 'package:english_mobile_app/features/progress/presentation/progress_screen.dart';
import 'package:english_mobile_app/features/progress/presentation/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sprint 7 - FeedbackRepository & Controllers Tests', () {
    test('Loads SessionReport with 4 rubric dimensions and corrections',
        () async {
      final repo = MockFeedbackRepository();
      final report = await repo.getSessionReport('sess_101');

      expect(report.sessionId, 'sess_101');
      expect(report.overallBand, 6.0);
      expect(report.dimensionScores.length, 4);
      expect(report.keyCorrections.length, greaterThanOrEqualTo(2));
      expect(report.coachAdviceVi, isNotEmpty);
      expect(report.recommendedDrillId, isNotEmpty);
    });

    test('Loads ProgressAnalyticsData and updates when period changes',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Period 0: Week
      var data =
          await container.read(progressAnalyticsControllerProvider.future);
      expect(data.weeklyBars.length, 7);
      expect(data.currentStreak, 5);
      expect(data.currentBands[RubricDimension.fluency], 6.0);

      // Change to Period 1: Month
      container.read(progressPeriodProvider.notifier).state = 1;
      data = await container.read(progressAnalyticsControllerProvider.future);
      expect(data.weeklyBars.length, 4);
      expect(data.totalMinutes, 320);
    });

    test('Loads practice history and filters by mode and search query',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var sessions =
          await container.read(practiceHistoryControllerProvider.future);
      expect(sessions.length, 4);

      // Filter by guided mode
      container.read(historyFilterModeProvider.notifier).state = 'guided';
      sessions = await container.read(practiceHistoryControllerProvider.future);
      expect(sessions.every((s) => s.mode == SessionMode.guided), isTrue);

      // Filter by search query
      container.read(historyFilterModeProvider.notifier).state = 'all';
      container.read(historySearchQueryProvider.notifier).state = 'nhà hàng';
      sessions = await container.read(practiceHistoryControllerProvider.future);
      expect(sessions.length, 1);
      expect(sessions.first.scenarioTitle, contains('nhà hàng'));
    });
  });

  group('Sprint 7 - UI Widget Smoke Tests', () {
    testWidgets(
        'SessionSummaryScreen (Screen 13) renders rubric report and disclaimer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SessionSummaryScreen(sessionId: 'sess_101'),
          ),
        ),
      );

      // Settle future
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SessionSummaryScreen), findsOneWidget);
      expect(
          find.textContaining('Hoàn thành phiên luyện tập!'), findsOneWidget);
      expect(find.textContaining('Band 6.0 (Tham khảo)'), findsOneWidget);
      expect(find.textContaining('Tuyên bố học thuật'), findsOneWidget);
      expect(
          find.textContaining('Đánh giá 4 tiêu chí năng lực'), findsOneWidget);
      expect(
          find.textContaining('Phân tích sửa lỗi Trước ➔ Sau'), findsOneWidget);
    });

    testWidgets(
        'ProgressScreen (Screen 14) renders period toggle, stat cards, and chart',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProgressScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ProgressScreen), findsOneWidget);
      expect(find.text('Tuần này'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(find.textContaining('Thời lượng nói'), findsOneWidget);
      expect(
          find.textContaining('Thời gian luyện nói mỗi ngày'), findsOneWidget);
      expect(find.textContaining('Tiến bộ theo 4 tiêu chí Rubric'),
          findsOneWidget);
    });

    testWidgets(
        'HistoryScreen (Screen 15) renders search bar, filters, and session list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.textContaining('Gọi món tại nhà hàng Ý'), findsOneWidget);
    });
  });
}
