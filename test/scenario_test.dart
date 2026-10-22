import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/core/models/enums.dart';
import 'package:english_mobile_app/features/scenarios/data/scenario_repository.dart';
import 'package:english_mobile_app/features/onboarding/presentation/controllers/placement_controller.dart';
import 'package:english_mobile_app/features/onboarding/domain/models/placement_models.dart';

void main() {
  group('ScenarioRepository Tests (G2 Compliance)', () {
    late ScenarioRepository repository;

    setUp(() {
      repository = LocalScenarioRepository();
    });

    test('Loads 4 required topic groups', () async {
      final topics = await repository.getTopics();
      expect(topics.length, 4);
      expect(topics.map((t) => t.id).toSet(),
          containsAll(['tp_intro', 'tp_daily', 'tp_travel', 'tp_career']));
    });

    test('Contains at least 12 scenarios across topics (G2 Requirement)',
        () async {
      final scenarios = await repository.getScenarios();
      expect(scenarios.length, greaterThanOrEqualTo(12));
    });

    test('Filters scenarios by topic correctly', () async {
      final travelScenarios =
          await repository.getScenarios(topicId: 'tp_travel');
      expect(travelScenarios.isNotEmpty, true);
      for (final s in travelScenarios) {
        expect(s.topicId, 'tp_travel');
      }
    });

    test('Filters scenarios by level correctly', () async {
      final a2Scenarios = await repository.getScenarios(level: UserLevel.a2);
      expect(a2Scenarios.isNotEmpty, true);
      for (final s in a2Scenarios) {
        expect(s.level, UserLevel.a2);
      }
    });

    test('Searches by keyword in title and roles', () async {
      final results = await repository.getScenarios(searchQuery: 'nhà hàng');
      expect(results.any((s) => s.id == 'sc_travel_01'), true);
    });

    test('Toggles bookmark for scenario', () async {
      final initialBookmarked = await repository.toggleBookmark('sc_intro_01');
      expect(initialBookmarked, true);

      final scenario = await repository.getScenarioById('sc_intro_01');
      expect(scenario?.isBookmarked, true);

      final secondToggle = await repository.toggleBookmark('sc_intro_01');
      expect(secondToggle, false);
    });
  });

  group('PlacementController Tests', () {
    test('Calculates result based on submitted answers', () async {
      const questions = [
        PlacementQuestion(
          id: 'q1',
          targetLevel: UserLevel.a1,
          title: 'Q1',
          promptEn: 'Intro',
          promptVi: 'Giới thiệu',
        ),
        PlacementQuestion(
          id: 'q2',
          targetLevel: UserLevel.a2,
          title: 'Q2',
          promptEn: 'Weekend',
          promptVi: 'Cuối tuần',
        ),
      ];

      final controller = PlacementController(questions);
      controller.submitAnswer('q1', 'Hello, my name is Bao.');
      controller.submitAnswer('q2', 'On weekends I play tennis.');

      await controller.calculateResult();

      expect(controller.state.result, isNotNull);
      expect(controller.state.result?.estimatedLevel, UserLevel.a2);
      expect(controller.state.result?.confidence, greaterThanOrEqualTo(0.8));
    });
  });
}
