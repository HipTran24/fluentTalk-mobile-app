import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/scenario.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../scenarios/presentation/controllers/scenario_controller.dart';

class HomeDashboardState {
  final String greeting;
  final String userName;
  final UserLevel userLevel;
  final int streakDays;
  final int todayMinutes;
  final int dailyGoalMinutes;
  final int weeklyMinutes;
  final String nextLessonTitle;
  final String nextLessonDesc;
  final String nextLessonScenarioId;
  final String nextLessonWhy;
  final String microInsightTitle;
  final String microInsightEvidence;
  final bool hasActiveSession;
  final String? activeSessionId;
  final String? activeSessionTitle;
  final List<Scenario> recommendedScenarios;
  final bool isLoading;

  const HomeDashboardState({
    required this.greeting,
    required this.userName,
    required this.userLevel,
    this.streakDays = 5,
    this.todayMinutes = 10,
    this.dailyGoalMinutes = 15,
    this.weeklyMinutes = 68,
    this.nextLessonTitle = 'Phản xạ: Gọi món tại nhà hàng Ý',
    this.nextLessonDesc = 'Thực hành cấu trúc "Could I have..." và hỏi món đặc sản của quán.',
    this.nextLessonScenarioId = 'sc_travel_01',
    this.nextLessonWhy = 'Dựa trên lỗi dùng từ vựng ẩm thực và liên từ ở phiên gần nhất',
    this.microInsightTitle = 'Bạn đã tự tin hơn 20% trong phản xạ câu hỏi!',
    this.microInsightEvidence = 'Độ ngập ngừng giảm từ 4.2s xuống 2.1s qua 5 phiên gần nhất.',
    this.hasActiveSession = false,
    this.activeSessionId,
    this.activeSessionTitle,
    this.recommendedScenarios = const [],
    this.isLoading = false,
  });

  HomeDashboardState copyWith({
    String? greeting,
    String? userName,
    UserLevel? userLevel,
    int? streakDays,
    int? todayMinutes,
    int? dailyGoalMinutes,
    int? weeklyMinutes,
    String? nextLessonTitle,
    String? nextLessonDesc,
    String? nextLessonScenarioId,
    String? nextLessonWhy,
    String? microInsightTitle,
    String? microInsightEvidence,
    bool? hasActiveSession,
    String? activeSessionId,
    String? activeSessionTitle,
    List<Scenario>? recommendedScenarios,
    bool? isLoading,
  }) {
    return HomeDashboardState(
      greeting: greeting ?? this.greeting,
      userName: userName ?? this.userName,
      userLevel: userLevel ?? this.userLevel,
      streakDays: streakDays ?? this.streakDays,
      todayMinutes: todayMinutes ?? this.todayMinutes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      weeklyMinutes: weeklyMinutes ?? this.weeklyMinutes,
      nextLessonTitle: nextLessonTitle ?? this.nextLessonTitle,
      nextLessonDesc: nextLessonDesc ?? this.nextLessonDesc,
      nextLessonScenarioId: nextLessonScenarioId ?? this.nextLessonScenarioId,
      nextLessonWhy: nextLessonWhy ?? this.nextLessonWhy,
      microInsightTitle: microInsightTitle ?? this.microInsightTitle,
      microInsightEvidence: microInsightEvidence ?? this.microInsightEvidence,
      hasActiveSession: hasActiveSession ?? this.hasActiveSession,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      activeSessionTitle: activeSessionTitle ?? this.activeSessionTitle,
      recommendedScenarios: recommendedScenarios ?? this.recommendedScenarios,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final homeDashboardControllerProvider =
    StateNotifierProvider<HomeDashboardController, HomeDashboardState>((ref) {
  return HomeDashboardController(ref);
});

class HomeDashboardController extends StateNotifier<HomeDashboardState> {
  final Ref _ref;

  HomeDashboardController(this._ref)
      : super(HomeDashboardState(
          greeting: _computeGreeting(),
          userName: 'Người học',
          userLevel: UserLevel.a2,
        )) {
    loadDashboard();
  }

  static String _computeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng! 🌅';
    } else if (hour < 18) {
      return 'Chào buổi chiều! ☀️';
    } else {
      return 'Chào buổi tối! 🌙';
    }
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);

    // Sync with auth state
    final authState = _ref.read(authControllerProvider);
    final user = authState.user;

    final userName = (user?.displayName.isNotEmpty == true) ? user!.displayName : 'Lê Nam';
    final userLevel = user?.level ?? UserLevel.a2;
    final dailyGoal = user?.dailyMinutes ?? 15;

    // Load scenarios from repository
    final scenarioRepo = _ref.read(scenarioRepositoryProvider);
    final allScenarios = await scenarioRepo.getScenarios();

    if (!mounted) return;

    // Filter recommended based on user level and popular topics
    final recommended = allScenarios.where((s) => s.level == userLevel || s.level == UserLevel.a2).take(4).toList();

    state = state.copyWith(
      greeting: _computeGreeting(),
      userName: userName,
      userLevel: userLevel,
      dailyGoalMinutes: dailyGoal,
      recommendedScenarios: recommended.isNotEmpty ? recommended : allScenarios.take(3).toList(),
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}
