import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feedback_repository.dart';
import '../../domain/models/feedback_models.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return MockFeedbackRepository();
});

final sessionSummaryControllerProvider =
    FutureProvider.family<SessionReport, String>((ref, sessionId) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getSessionReport(sessionId);
});
