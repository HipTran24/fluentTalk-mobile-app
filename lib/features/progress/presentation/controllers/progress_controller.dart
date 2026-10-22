import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/practice_session.dart';
import '../../../feedback/presentation/controllers/session_summary_controller.dart';
import '../../../feedback/domain/models/feedback_models.dart';

final progressPeriodProvider =
    StateProvider<int>((ref) => 0); // 0: Tuần, 1: Tháng, 2: Tất cả

final progressAnalyticsControllerProvider =
    FutureProvider<ProgressAnalyticsData>((ref) async {
  final period = ref.watch(progressPeriodProvider);
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getProgressAnalytics(period);
});

final historyFilterModeProvider = StateProvider<String>(
    (ref) => 'all'); // 'all', 'guided', 'realtime', 'text'
final historySearchQueryProvider = StateProvider<String>((ref) => '');

final practiceHistoryControllerProvider =
    FutureProvider<List<PracticeSession>>((ref) async {
  final mode = ref.watch(historyFilterModeProvider);
  final query = ref.watch(historySearchQueryProvider);
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getPracticeHistory(modeFilter: mode, searchQuery: query);
});
