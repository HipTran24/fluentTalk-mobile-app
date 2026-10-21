import '../models/admin_models.dart';

abstract class IAdminRepository {
  Future<AdminKpiSummary> getKpiSummary();
  Future<List<AdminLearner>> getLearners({String query = '', String levelFilter = 'all'});
  Future<void> toggleLearnerStatus(String learnerId);
  Future<List<AdminScenarioItem>> getScenarios({String query = '', String topicFilter = 'all'});
  Future<void> saveScenario(AdminScenarioItem scenario);
  Future<void> toggleScenarioStatus(String scenarioId);
  Future<void> deleteScenario(String scenarioId);
  Future<AdminAiConfig> getAiConfig();
  Future<void> updateAiConfig(AdminAiConfig config);
}
