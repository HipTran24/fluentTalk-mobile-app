import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_mobile_app/core/models/enums.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/models/admin_models.dart';
import '../domain/repository/i_admin_repository.dart';

final adminRepositoryProvider = Provider<IAdminRepository>((ref) {
  return AdminRepository();
});

class AdminRepository implements IAdminRepository {
  // In-memory state for CRUD operations
  final List<AdminScenarioItem> _scenarios = [
    const AdminScenarioItem(
      id: 'sc_travel_01',
      title: 'Check-in tại khách sạn Quốc tế',
      topicId: 'travel',
      topicName: 'Du lịch & Khách sạn',
      level: UserLevel.a2,
      aiRole: 'Lễ tân khách sạn (Hotel Receptionist)',
      userRole: 'Khách du lịch (Traveler)',
      estimatedMinutes: 6,
      usageCount: 1420,
      avgScore: 8.2,
      isActive: true,
      keyPhrases: ['reservation under name', 'room on higher floor', 'breakfast included'],
    ),
    const AdminScenarioItem(
      id: 'sc_cafe_01',
      title: 'Đặt cà phê & Bánh ngọt take-away',
      topicId: 'daily',
      topicName: 'Đời sống thường nhật',
      level: UserLevel.a1,
      aiRole: 'Nhân viên pha chế (Barista)',
      userRole: 'Khách hàng (Customer)',
      estimatedMinutes: 4,
      usageCount: 2310,
      avgScore: 8.6,
      isActive: true,
      keyPhrases: ['oat milk latte', 'less sugar please', 'to-go cup'],
    ),
    const AdminScenarioItem(
      id: 'sc_work_01',
      title: 'Phỏng vấn xin việc Tech Lead',
      topicId: 'career',
      topicName: 'Công việc & Phỏng vấn',
      level: UserLevel.b2,
      aiRole: 'Giám đốc tuyển dụng (Hiring Manager)',
      userRole: 'Ứng viên (Candidate)',
      estimatedMinutes: 12,
      usageCount: 980,
      avgScore: 7.5,
      isActive: true,
      keyPhrases: ['system architecture', 'conflict resolution', 'scalable backend'],
    ),
    const AdminScenarioItem(
      id: 'sc_ielts_01',
      title: 'Luyện IELTS Speaking Part 2 - Thành phố yêu thích',
      topicId: 'exam',
      topicName: 'Luyện thi chứng chỉ',
      level: UserLevel.b2,
      aiRole: 'Giám khảo khảo thí (IELTS Examiner)',
      userRole: 'Thí sinh (Examinee)',
      estimatedMinutes: 10,
      usageCount: 1150,
      avgScore: 7.4,
      isActive: true,
      keyPhrases: ['hustle and bustle', 'cultural heritage', 'picturesque landscape'],
    ),
    const AdminScenarioItem(
      id: 'sc_tech_01',
      title: 'Báo cáo Daily Standup với Team quốc tế',
      topicId: 'career',
      topicName: 'Công việc & Phỏng vấn',
      level: UserLevel.b1,
      aiRole: 'Scrum Master',
      userRole: 'Frontend Developer',
      estimatedMinutes: 5,
      usageCount: 840,
      avgScore: 7.9,
      isActive: true,
      keyPhrases: ['what I did yesterday', 'blockers on API', 'pull request review'],
    ),
    const AdminScenarioItem(
      id: 'sc_airport_01',
      title: 'Xử lý thất lạc hành lý tại sân bay Heathrow',
      topicId: 'travel',
      topicName: 'Du lịch & Khách sạn',
      level: UserLevel.b1,
      aiRole: 'Nhân viên hành lý thất lạc (Baggage Claim Agent)',
      userRole: 'Hành khách (Passenger)',
      estimatedMinutes: 8,
      usageCount: 620,
      avgScore: 7.7,
      isActive: true,
      keyPhrases: ['luggage tag receipt', 'black hard-shell suitcase', 'delivery address'],
    ),
  ];

  final List<AdminLearner> _learners = [];

  AdminAiConfig _aiConfig = const AdminAiConfig(
    modelName: 'gemini-1.5-flash-live',
    temperature: 0.7,
    bargeInSensitivity: 0.85,
    maxTurnDurationSec: 90,
    systemPrompt: '''You are an empathetic, professional English conversation partner.
Guidelines:
1. Stay in character based on the scenario role.
2. Keep spoken responses concise (1 to 2 sentences) to encourage learner speaking time.
3. If learner makes grammar mistakes, maintain conversational flow, then provide subtle recasting.
4. If learner pauses for >3 seconds, offer gentle encouraging cues.''',
    preferredTtsVoice: 'en-US-Journey-F',
    monthlyTokenQuota: 5000000,
    monthlyTokensUsed: 1485200,
    activeWebSocketConnections: 42,
  );

  @override
  Future<AdminKpiSummary> getKpiSummary() async {
    await Future.delayed(const Duration(milliseconds: 60));

    // Ensure learners are populated from registered accounts
    await getLearners();

    final count = _learners.length;
    final totalVoice = _learners.fold<int>(0, (sum, l) => sum + l.voiceMinutes);
    final activeSessions = _learners.where((l) => l.isActive).length;

    final activities = <AdminActivityItem>[];
    for (final learner in _learners) {
      activities.add(
        AdminActivityItem(
          id: 'act_${learner.id}',
          title: 'Học viên ${learner.name} đã đăng ký tài khoản',
          description: 'Email: ${learner.email} • Cấp độ: ${learner.level.name.toUpperCase()} • Mục tiêu: ${learner.goal.title}',
          timeAgo: 'Đã ghi nhận',
          type: 'signup',
        ),
      );
    }

    if (activities.isEmpty) {
      activities.add(
        const AdminActivityItem(
          id: 'act_ready',
          title: 'Hệ thống quản trị sẵn sàng',
          description: 'Chưa có tài khoản nào đăng ký. Danh bạ sẽ tự động ghi nhận khi học viên đăng ký mới.',
          timeAgo: 'Hiện tại',
          type: 'alert',
        ),
      );
    }

    // Weekly metrics based on registered voice time
    final dailyAvg = count > 0 ? (totalVoice / 7).round() : 0;
    final weekly = [
      AdminDailyMetric(dayLabel: 'T2', voiceMinutes: dailyAvg, sessionCount: count),
      AdminDailyMetric(dayLabel: 'T3', voiceMinutes: dailyAvg, sessionCount: count),
      AdminDailyMetric(dayLabel: 'T4', voiceMinutes: dailyAvg, sessionCount: count),
      AdminDailyMetric(dayLabel: 'T5', voiceMinutes: dailyAvg, sessionCount: count),
      AdminDailyMetric(dayLabel: 'T6', voiceMinutes: dailyAvg, sessionCount: count),
      AdminDailyMetric(dayLabel: 'T7', voiceMinutes: dailyAvg, sessionCount: count),
      AdminDailyMetric(dayLabel: 'CN', voiceMinutes: dailyAvg, sessionCount: count),
    ];

    return AdminKpiSummary(
      totalLearners: count,
      learnerGrowthPct: count > 0 ? 100.0 : 0.0,
      totalVoiceMinutes: totalVoice,
      voiceGrowthPct: count > 0 ? 100.0 : 0.0,
      activeSessionsToday: activeSessions,
      geminiTokensUsed: '${(count * 0.05).toStringAsFixed(2)}M / 5.0M',
      avgFluencyScore: count > 0 ? 8.2 : 0.0,
      weeklyTrends: weekly,
      recentActivities: activities,
    );
  }

  @override
  Future<List<AdminLearner>> getLearners({String query = '', String levelFilter = 'all'}) async {
    await Future.delayed(const Duration(milliseconds: 60));

    // Load actual registered accounts from local persistence
    final registeredUsers = await LocalAuthRepository.getRegisteredUsers();

    for (final u in registeredUsers) {
      final existingIndex = _learners.indexWhere((l) => l.email.toLowerCase() == u.email.toLowerCase());
      if (existingIndex == -1) {
        _learners.add(
          AdminLearner(
            id: u.id,
            name: u.displayName,
            email: u.email,
            level: u.level,
            goal: u.goal,
            totalSessions: 1,
            voiceMinutes: u.dailyMinutes,
            streakDays: u.currentStreak,
            isActive: true,
            lastActiveAt: u.updatedAt ?? u.createdAt,
          ),
        );
      } else {
        final cur = _learners[existingIndex];
        _learners[existingIndex] = cur.copyWith(
          name: u.displayName,
          level: u.level,
          goal: u.goal,
          streakDays: u.currentStreak,
          voiceMinutes: u.dailyMinutes,
        );
      }
    }

    return _learners.where((l) {
      final matchesQuery = query.isEmpty ||
          l.name.toLowerCase().contains(query.toLowerCase()) ||
          l.email.toLowerCase().contains(query.toLowerCase());
      final matchesLevel = levelFilter == 'all' || l.level.name.toLowerCase() == levelFilter.toLowerCase();
      return matchesQuery && matchesLevel;
    }).toList();
  }

  @override
  Future<void> toggleLearnerStatus(String learnerId) async {
    final idx = _learners.indexWhere((l) => l.id == learnerId);
    if (idx != -1) {
      _learners[idx] = _learners[idx].copyWith(isActive: !_learners[idx].isActive);
    }
  }

  @override
  Future<List<AdminScenarioItem>> getScenarios({String query = '', String topicFilter = 'all'}) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _scenarios.where((s) {
      final matchesQuery = query.isEmpty ||
          s.title.toLowerCase().contains(query.toLowerCase()) ||
          s.aiRole.toLowerCase().contains(query.toLowerCase()) ||
          s.userRole.toLowerCase().contains(query.toLowerCase());
      final matchesTopic = topicFilter == 'all' || s.topicId == topicFilter;
      return matchesQuery && matchesTopic;
    }).toList();
  }

  @override
  Future<void> saveScenario(AdminScenarioItem scenario) async {
    final idx = _scenarios.indexWhere((s) => s.id == scenario.id);
    if (idx != -1) {
      _scenarios[idx] = scenario;
    } else {
      _scenarios.insert(0, scenario);
    }
  }

  @override
  Future<void> toggleScenarioStatus(String scenarioId) async {
    final idx = _scenarios.indexWhere((s) => s.id == scenarioId);
    if (idx != -1) {
      _scenarios[idx] = _scenarios[idx].copyWith(isActive: !_scenarios[idx].isActive);
    }
  }

  @override
  Future<void> deleteScenario(String scenarioId) async {
    _scenarios.removeWhere((s) => s.id == scenarioId);
  }

  @override
  Future<AdminAiConfig> getAiConfig() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _aiConfig;
  }

  @override
  Future<void> updateAiConfig(AdminAiConfig config) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _aiConfig = config;
  }
}
