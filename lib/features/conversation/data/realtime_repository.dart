import '../domain/models/realtime_models.dart';

abstract class RealtimeCallRepository {
  Future<List<ConversationTopicHint>> getTopicHints(String scenarioId);
  Future<List<RealtimeCaptionItem>> getInitialConversation(String scenarioId);
  Future<void> endCallSession(String sessionId, int durationSeconds);
}

class MockRealtimeCallRepository implements RealtimeCallRepository {
  @override
  Future<List<ConversationTopicHint>> getTopicHints(String scenarioId) async {
    return const [
      ConversationTopicHint(
        title: 'Hỏi ý kiến cá nhân',
        englishPhrase: 'What do you think about remote work culture?',
        vietnameseMeaning: 'Bạn nghĩ gì về văn hóa làm việc từ xa?',
      ),
      ConversationTopicHint(
        title: 'Kể về trải nghiệm du lịch',
        englishPhrase: 'Have you ever had an unforgettable trip abroad?',
        vietnameseMeaning:
            'Bạn đã từng có một chuyến đi nước ngoài khó quên nào chưa?',
      ),
      ConversationTopicHint(
        title: 'Bày tỏ sự đồng thuận',
        englishPhrase:
            'That makes total sense! Could you tell me more about that?',
        vietnameseMeaning:
            'Điều đó hoàn toàn hợp lý! Bạn có thể nói thêm về điều đó không?',
      ),
      ConversationTopicHint(
        title: 'Yêu cầu giải thích lại',
        englishPhrase:
            'Sorry, could you explain that last point in a simpler way?',
        vietnameseMeaning:
            'Xin lỗi, bạn có thể giải thích ý vừa rồi đơn giản hơn không?',
      ),
    ];
  }

  @override
  Future<List<RealtimeCaptionItem>> getInitialConversation(
      String scenarioId) async {
    return [
      RealtimeCaptionItem(
        id: 'cap_01',
        speaker: 'ai',
        text:
            'Hello! I am Tom. How has your day been so far? Tell me something interesting that happened today.',
        timestamp: DateTime.now().subtract(const Duration(seconds: 15)),
      ),
    ];
  }

  @override
  Future<void> endCallSession(String sessionId, int durationSeconds) async {
    // Simulate backend call persistence
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
