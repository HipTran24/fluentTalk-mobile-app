import 'package:english_mobile_app/features/admin/domain/models/admin_models.dart';

class AdminState {
  final int currentTabIndex; // 0: Dashboard, 1: Scenarios, 2: Users, 3: AI Config
  final bool isLoading;
  final AdminKpiSummary? kpiSummary;
  final List<AdminScenarioItem> scenarios;
  final List<AdminLearner> learners;
  final AdminAiConfig? aiConfig;
  final String scenarioQuery;
  final String scenarioTopicFilter;
  final String userQuery;
  final String userLevelFilter;
  final String? statusMessage;

  const AdminState({
    this.currentTabIndex = 0,
    this.isLoading = false,
    this.kpiSummary,
    this.scenarios = const [],
    this.learners = const [],
    this.aiConfig,
    this.scenarioQuery = '',
    this.scenarioTopicFilter = 'all',
    this.userQuery = '',
    this.userLevelFilter = 'all',
    this.statusMessage,
  });

  AdminState copyWith({
    int? currentTabIndex,
    bool? isLoading,
    AdminKpiSummary? kpiSummary,
    List<AdminScenarioItem>? scenarios,
    List<AdminLearner>? learners,
    AdminAiConfig? aiConfig,
    String? scenarioQuery,
    String? scenarioTopicFilter,
    String? userQuery,
    String? userLevelFilter,
    String? statusMessage,
  }) {
    return AdminState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      isLoading: isLoading ?? this.isLoading,
      kpiSummary: kpiSummary ?? this.kpiSummary,
      scenarios: scenarios ?? this.scenarios,
      learners: learners ?? this.learners,
      aiConfig: aiConfig ?? this.aiConfig,
      scenarioQuery: scenarioQuery ?? this.scenarioQuery,
      scenarioTopicFilter: scenarioTopicFilter ?? this.scenarioTopicFilter,
      userQuery: userQuery ?? this.userQuery,
      userLevelFilter: userLevelFilter ?? this.userLevelFilter,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
