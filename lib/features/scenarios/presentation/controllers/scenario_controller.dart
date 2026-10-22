import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/scenario.dart';
import '../../data/scenario_repository.dart';
import '../../data/remote_scenario_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final scenarioRepositoryProvider = Provider<ScenarioRepository>((ref) {
  if (ref.watch(appConfigProvider).demoMode) return LocalScenarioRepository();
  return RemoteScenarioRepository(ref.watch(apiClientProvider));
});

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  return repo.getTopics();
});

final selectedTopicIdProvider = StateProvider<String>((ref) => 'all');
final selectedLevelProvider = StateProvider<UserLevel?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCatalogTabProvider = StateProvider<String>((ref) => 'all');

// A filter change restarts pagination; old pages never carry into a new query.
final catalogPageIndexProvider = StateProvider<int>((ref) {
  ref.watch(selectedTopicIdProvider);
  ref.watch(selectedLevelProvider);
  ref.watch(searchQueryProvider);
  ref.watch(selectedCatalogTabProvider);
  return 0;
});

final catalogPageProvider = FutureProvider<ScenarioPage>((ref) {
  return ref.watch(scenarioRepositoryProvider).getScenarioPage(
        topicId: ref.watch(selectedTopicIdProvider),
        level: ref.watch(selectedLevelProvider),
        searchQuery: ref.watch(searchQueryProvider),
        filterTab: ref.watch(selectedCatalogTabProvider),
        page: ref.watch(catalogPageIndexProvider),
      );
});

final filteredScenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  final topicId = ref.watch(selectedTopicIdProvider);
  final level = ref.watch(selectedLevelProvider);
  final query = ref.watch(searchQueryProvider);
  final tab = ref.watch(selectedCatalogTabProvider);

  return repo.getScenarios(
    topicId: topicId,
    level: level,
    searchQuery: query,
    filterTab: tab,
  );
});

final scenarioDetailProvider =
    FutureProvider.family<Scenario?, String>((ref, id) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  return repo.getScenarioById(id);
});

final bookmarkControllerProvider = Provider((ref) {
  final repo = ref.watch(scenarioRepositoryProvider);
  return BookmarkController(repo, ref);
});

class BookmarkController {
  final ScenarioRepository _repo;
  final Ref _ref;

  BookmarkController(this._repo, this._ref);

  Future<bool> toggle(String scenarioId) async {
    final result = await _repo.toggleBookmark(scenarioId);
    _ref.invalidate(filteredScenariosProvider);
    _ref.invalidate(catalogPageProvider);
    _ref.invalidate(scenarioDetailProvider(scenarioId));
    return result;
  }
}
