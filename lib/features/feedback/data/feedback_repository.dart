import '../../../core/models/assessment.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/practice_session.dart';
import '../domain/models/feedback_models.dart';

abstract class FeedbackRepository {
  Future<SessionReport> getSessionReport(String sessionId);
  Future<ProgressAnalyticsData> getProgressAnalytics(int periodIndex);
  Future<List<PracticeSession>> getPracticeHistory(
      {String? modeFilter, String? searchQuery});
}

class MockFeedbackRepository implements FeedbackRepository {
  @override
  Future<SessionReport> getSessionReport(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return SessionReport(
      sessionId: sessionId,
      scenarioTitle: 'Phản xạ: Gọi món tại nhà hàng Ý',
      mode: SessionMode.guided,
      completedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      durationSeconds: 270,
      turnsCount: 4,
      overallBand: 6.0,
      cefrLevel: UserLevel.b1,
      dimensionScores: const [
        DimensionScore(
          dimension: RubricDimension.fluency,
          estimatedBand: 6.5,
          feedbackVi:
              'Tốc độ phản xạ nhanh, độ ngập ngừng giảm đáng kể so với phiên trước.',
          evidenceSnippets: [
            'Could we please have a bottle of sparkling water and some fresh orange juice?'
          ],
        ),
        DimensionScore(
          dimension: RubricDimension.lexical,
          estimatedBand: 6.0,
          feedbackVi:
              'Sử dụng chính xác các cụm từ nhà hàng: "table for two", "reservation", "specialty".',
          evidenceSnippets: ['Is this dish quite spicy, or mild?'],
        ),
        DimensionScore(
          dimension: RubricDimension.grammar,
          estimatedBand: 5.5,
          feedbackVi:
              'Cần chú ý thêm mạo từ "the" và chia thì quá khứ đơn trong câu trần thuật.',
          evidenceSnippets: [
            'Yesterday I go to market (cần: went to the market)'
          ],
        ),
        DimensionScore(
          dimension: RubricDimension.pronunciation,
          estimatedBand: 6.0,
          feedbackVi:
              'Bật âm đuôi /s/, /z/ và /t/ tốt. Ngữ điệu câu hỏi lịch sự tự nhiên.',
          evidenceSnippets: ['reservation', 'sparkling', 'available'],
          hasAcousticEvidence: true,
        ),
      ],
      keyCorrections: const [
        CorrectionItem(
          original: 'Yesterday I go to market to buy food.',
          suggested: 'Yesterday I went to the market to buy some groceries.',
          explanationVi:
              'Với trạng từ thời gian quá khứ ("yesterday"), động từ "go" phải chuyển thành "went". Dùng "the market" và từ vựng tự nhiên hơn "groceries".',
          type: 'grammar',
        ),
        CorrectionItem(
          original: 'We have no table booked.',
          suggested:
              'We do not have a reservation, do you have any table available?',
          explanationVi:
              'Cách diễn đạt tự nhiên chuẩn bản xứ trong nhà hàng khi chưa đặt chỗ trước.',
          type: 'vocabulary',
        ),
      ],
      coachAdviceVi:
          'Bạn đang tiến bộ rất nhanh ở phản xạ tự tin! Hãy dành thêm 3 phút luyện bài tập ngắn về thì Quá khứ đơn để củng cố điểm Ngữ pháp nhé.',
      recommendedDrillId: 'drill_past_tense_01',
      recommendedDrillTitle: 'Drill 3 phút: Phản xạ thì Quá khứ đơn',
    );
  }

  @override
  Future<ProgressAnalyticsData> getProgressAnalytics(int periodIndex) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (periodIndex == 1) {
      // Tháng này
      return const ProgressAnalyticsData(
        totalMinutes: 320,
        totalSessions: 38,
        currentStreak: 7,
        weeklyBars: [
          DailyPracticeBar(dayLabel: 'Tuần 1', minutes: 75),
          DailyPracticeBar(dayLabel: 'Tuần 2', minutes: 82),
          DailyPracticeBar(dayLabel: 'Tuần 3', minutes: 90),
          DailyPracticeBar(dayLabel: 'Tuần 4', minutes: 73, isToday: true),
        ],
        currentBands: {
          RubricDimension.fluency: 6.0,
          RubricDimension.lexical: 6.0,
          RubricDimension.grammar: 5.5,
          RubricDimension.pronunciation: 6.5,
        },
        bandGrowth: {
          RubricDimension.fluency: 0.5,
          RubricDimension.lexical: 0.5,
          RubricDimension.grammar: 0.0,
          RubricDimension.pronunciation: 0.5,
        },
      );
    }

    // Mặc định: Tuần này
    return const ProgressAnalyticsData(
      totalMinutes: 78,
      totalSessions: 9,
      currentStreak: 5,
      weeklyBars: [
        DailyPracticeBar(dayLabel: 'T2', minutes: 12),
        DailyPracticeBar(dayLabel: 'T3', minutes: 15),
        DailyPracticeBar(dayLabel: 'T4', minutes: 10),
        DailyPracticeBar(dayLabel: 'T5', minutes: 18),
        DailyPracticeBar(dayLabel: 'T6', minutes: 15, isToday: true),
        DailyPracticeBar(dayLabel: 'T7', minutes: 8),
        DailyPracticeBar(dayLabel: 'CN', minutes: 0),
      ],
      currentBands: {
        RubricDimension.fluency: 6.0,
        RubricDimension.lexical: 5.5,
        RubricDimension.grammar: 5.5,
        RubricDimension.pronunciation: 6.0,
      },
      bandGrowth: {
        RubricDimension.fluency: 0.5,
        RubricDimension.lexical: 0.5,
        RubricDimension.grammar: 0.0,
        RubricDimension.pronunciation: 0.5,
      },
    );
  }

  @override
  Future<List<PracticeSession>> getPracticeHistory(
      {String? modeFilter, String? searchQuery}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final list = [
      PracticeSession(
        id: 'sess_101',
        userId: 'usr_me',
        scenarioId: 'sc_travel_01',
        scenarioTitle: 'Gọi món tại nhà hàng Ý',
        mode: SessionMode.guided,
        status: SessionStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        durationSeconds: 270,
        turnsCount: 4,
        estimatedScore: 6.0,
      ),
      PracticeSession(
        id: 'sess_100',
        userId: 'usr_me',
        scenarioId: 'sc_travel_02',
        scenarioTitle: 'Check-in tại sân bay quốc tế',
        mode: SessionMode.realtime,
        status: SessionStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        durationSeconds: 370,
        turnsCount: 6,
        estimatedScore: 5.5,
      ),
      PracticeSession(
        id: 'sess_099',
        userId: 'usr_me',
        scenarioId: 'sc_intro_01',
        scenarioTitle: 'Làm quen & Chào hỏi cơ bản',
        mode: SessionMode.guided,
        status: SessionStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        durationSeconds: 210,
        turnsCount: 3,
        estimatedScore: 6.5,
      ),
      PracticeSession(
        id: 'sess_098',
        userId: 'usr_me',
        scenarioId: 'sc_daily_01',
        scenarioTitle: 'Mua sắm tại siêu thị',
        mode: SessionMode.text,
        status: SessionStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(days: 3)),
        durationSeconds: 180,
        turnsCount: 5,
        estimatedScore: 6.0,
      ),
    ];

    return list.where((s) {
      if (modeFilter != null && modeFilter != 'all') {
        if (s.mode.name != modeFilter) return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final titleMatch =
            s.scenarioTitle?.toLowerCase().contains(query) ?? false;
        if (!titleMatch) return false;
      }
      return true;
    }).toList();
  }
}
