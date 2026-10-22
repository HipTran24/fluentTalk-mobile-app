import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_mobile_app/features/admin/data/admin_repository.dart';
import 'package:english_mobile_app/features/admin/domain/models/admin_models.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_controller.dart';
import 'package:english_mobile_app/features/auth/data/auth_repository.dart';
import 'package:english_mobile_app/core/models/enums.dart';
import 'package:english_mobile_app/core/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminRepository Tests', () {
    late AdminRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalAuthRepository.saveRegisteredUser(UserProfile(
        id: 'usr_test_01',
        email: 'learner.test@fluenttalk.com',
        displayName: 'Học viên Test',
        level: UserLevel.b1,
        goal: LearningGoalType.work,
        dailyMinutes: 20,
        currentStreak: 2,
        createdAt: DateTime.now(),
      ));
      repo = AdminRepository();
    });

    test('Loads KPI summary with weekly trends and recent activities',
        () async {
      final kpi = await repo.getKpiSummary();
      expect(kpi.totalLearners, greaterThanOrEqualTo(1));
      expect(kpi.totalVoiceMinutes, greaterThanOrEqualTo(20));
      expect(kpi.weeklyTrends.length, equals(7));
      expect(kpi.recentActivities.isNotEmpty, isTrue);
    });

    test('Filters scenarios by topic and search query', () async {
      final allScenarios = await repo.getScenarios();
      expect(allScenarios.length, greaterThanOrEqualTo(5));

      final travelScenarios = await repo.getScenarios(topicFilter: 'travel');
      expect(travelScenarios.every((s) => s.topicId == 'travel'), isTrue);

      final searchResults = await repo.getScenarios(query: 'khách sạn');
      expect(searchResults.any((s) => s.title.contains('khách sạn')), isTrue);
    });

    test('Toggles scenario active status and deletes scenario', () async {
      final list = await repo.getScenarios();
      final target = list.first;
      final originalStatus = target.isActive;

      await repo.toggleScenarioStatus(target.id);
      final updated =
          (await repo.getScenarios()).firstWhere((s) => s.id == target.id);
      expect(updated.isActive, equals(!originalStatus));

      await repo.deleteScenario(target.id);
      final afterDelete = await repo.getScenarios();
      expect(afterDelete.any((s) => s.id == target.id), isFalse);
    });

    test('Loads and updates Tom configuration', () async {
      final config = await repo.getAiConfig();
      expect(config.modelName, contains('gemini'));
      expect(config.temperature, greaterThan(0));

      final updated =
          config.copyWith(temperature: 0.5, bargeInSensitivity: 0.95);
      await repo.updateAiConfig(updated);

      final reloaded = await repo.getAiConfig();
      expect(reloaded.temperature, equals(0.5));
      expect(reloaded.bargeInSensitivity, equals(0.95));
    });
  });

  group('AdminController Tests', () {
    late AdminRepository repo;
    late AdminController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalAuthRepository.saveRegisteredUser(UserProfile(
        id: 'usr_test_01',
        email: 'learner.test@fluenttalk.com',
        displayName: 'Học viên Test',
        level: UserLevel.b1,
        goal: LearningGoalType.work,
        dailyMinutes: 20,
        currentStreak: 2,
        createdAt: DateTime.now(),
      ));
      repo = AdminRepository();
      controller = AdminController(repo);
    });

    test('Initializes state with KPIs, scenarios, learners and Tom config',
        () async {
      await controller.loadAll();
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.kpiSummary, isNotNull);
      expect(controller.state.scenarios.isNotEmpty, isTrue);
      expect(
          controller.state.learners
              .any((l) => l.email == 'learner.test@fluenttalk.com'),
          isTrue);
      expect(controller.state.aiConfig, isNotNull);
    });

    test('Captures newly registered user in admin directory dynamically',
        () async {
      final authRepo = LocalAuthRepository();
      await authRepo.signUp(
        email: 'newbie@example.com',
        password: 'Password123',
        displayName: 'Nguyễn Văn Mới',
      );

      await controller.loadAll();
      expect(
          controller.state.learners.any((l) => l.email == 'newbie@example.com'),
          isTrue);
    });

    test('Switches tabs between Dashboard, Scenarios, Users, and Tom Config',
        () {
      expect(controller.state.currentTabIndex, equals(0));
      controller.switchTab(1);
      expect(controller.state.currentTabIndex, equals(1));
      controller.switchTab(2);
      expect(controller.state.currentTabIndex, equals(2));
      controller.switchTab(3);
      expect(controller.state.currentTabIndex, equals(3));
    });

    test('Creates and saves new scenario via controller', () async {
      await controller.loadAll();
      final initialCount = controller.state.scenarios.length;

      const newScenario = AdminScenarioItem(
        id: 'sc_test_new',
        title: 'Thử nghiệm phỏng vấn Visa',
        topicId: 'travel',
        topicName: 'Du lịch & Khách sạn',
        level: UserLevel.b1,
        aiRole: 'Visa Officer',
        userRole: 'Applicant',
        estimatedMinutes: 5,
        usageCount: 0,
        avgScore: 0.0,
        isActive: true,
        keyPhrases: ['purpose of visit', 'proof of funds'],
      );

      await controller.saveScenario(newScenario);
      expect(controller.state.scenarios.length, equals(initialCount + 1));
      expect(
          controller.state.scenarios.any((s) => s.id == 'sc_test_new'), isTrue);
    });
  });
}
