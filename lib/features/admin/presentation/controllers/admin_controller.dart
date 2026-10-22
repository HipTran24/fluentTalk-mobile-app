import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository.dart';
import '../../domain/models/admin_models.dart';
import '../../domain/repository/i_admin_repository.dart';
import 'admin_state.dart';

final adminControllerProvider =
    StateNotifierProvider<AdminController, AdminState>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminController(repo);
});

class AdminController extends StateNotifier<AdminState> {
  final IAdminRepository _repo;

  AdminController(this._repo) : super(const AdminState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, statusMessage: null);
    try {
      final kpi = await _repo.getKpiSummary();
      final scenarios = await _repo.getScenarios(
        query: state.scenarioQuery,
        topicFilter: state.scenarioTopicFilter,
      );
      final learners = await _repo.getLearners(
        query: state.userQuery,
        levelFilter: state.userLevelFilter,
      );
      final aiConfig = await _repo.getAiConfig();

      state = state.copyWith(
        isLoading: false,
        kpiSummary: kpi,
        scenarios: scenarios,
        learners: learners,
        aiConfig: aiConfig,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, statusMessage: 'Lỗi tải dữ liệu: $e');
    }
  }

  void switchTab(int index) {
    state = state.copyWith(currentTabIndex: index);
  }

  Future<void> searchScenarios(String query) async {
    state = state.copyWith(scenarioQuery: query);
    final scenarios = await _repo.getScenarios(
      query: query,
      topicFilter: state.scenarioTopicFilter,
    );
    state = state.copyWith(scenarios: scenarios);
  }

  Future<void> filterScenariosByTopic(String topicId) async {
    state = state.copyWith(scenarioTopicFilter: topicId);
    final scenarios = await _repo.getScenarios(
      query: state.scenarioQuery,
      topicFilter: topicId,
    );
    state = state.copyWith(scenarios: scenarios);
  }

  Future<void> toggleScenarioStatus(String scenarioId) async {
    await _repo.toggleScenarioStatus(scenarioId);
    final scenarios = await _repo.getScenarios(
      query: state.scenarioQuery,
      topicFilter: state.scenarioTopicFilter,
    );
    state = state.copyWith(
        scenarios: scenarios, statusMessage: 'Đã cập nhật trạng thái kịch bản');
  }

  Future<void> deleteScenario(String scenarioId) async {
    await _repo.deleteScenario(scenarioId);
    final scenarios = await _repo.getScenarios(
      query: state.scenarioQuery,
      topicFilter: state.scenarioTopicFilter,
    );
    state = state.copyWith(
        scenarios: scenarios, statusMessage: 'Đã xóa kịch bản khỏi danh mục');
  }

  Future<void> saveScenario(AdminScenarioItem scenario) async {
    await _repo.saveScenario(scenario);
    final scenarios = await _repo.getScenarios(
      query: state.scenarioQuery,
      topicFilter: state.scenarioTopicFilter,
    );
    state = state.copyWith(
        scenarios: scenarios, statusMessage: 'Đã lưu kịch bản thành công');
  }

  Future<void> searchLearners(String query) async {
    state = state.copyWith(userQuery: query);
    final learners = await _repo.getLearners(
      query: query,
      levelFilter: state.userLevelFilter,
    );
    state = state.copyWith(learners: learners);
  }

  Future<void> filterLearnersByLevel(String level) async {
    state = state.copyWith(userLevelFilter: level);
    final learners = await _repo.getLearners(
      query: state.userQuery,
      levelFilter: level,
    );
    state = state.copyWith(learners: learners);
  }

  Future<void> toggleLearnerStatus(String learnerId) async {
    await _repo.toggleLearnerStatus(learnerId);
    final learners = await _repo.getLearners(
      query: state.userQuery,
      levelFilter: state.userLevelFilter,
    );
    state = state.copyWith(
        learners: learners,
        statusMessage: 'Đã thay đổi trạng thái kích hoạt học viên');
  }

  Future<void> updateAiConfig(AdminAiConfig config) async {
    await _repo.updateAiConfig(config);
    state = state.copyWith(
        aiConfig: config,
        statusMessage: 'Đã lưu cấu hình Tom Gemini Live thành công');
  }
}
