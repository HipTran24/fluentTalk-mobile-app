import '../domain/models/chat_models.dart';

abstract class ChatRepository {
  Future<ChatMessage> sendTextMessage({
    required String text,
    required String idempotencyKey,
    String? userLevel,
  });
}

class MockChatRepository implements ChatRepository {
  final Set<String> _processedKeys = {};

  @override
  Future<ChatMessage> sendTextMessage({
    required String text,
    required String idempotencyKey,
    String? userLevel,
  }) async {
    // Idempotency check: prevent duplicate submits (Section 4.3 & MODE-01)
    if (_processedKeys.contains(idempotencyKey)) {
      throw Exception('Yêu cầu đã được gửi trước đó.');
    }
    _processedKeys.add(idempotencyKey);

    // Simulate AI thinking and voice synthesis latency
    await Future.delayed(const Duration(milliseconds: 900));

    final query = text.toLowerCase();
    String replyText = '';
    List<String> usefulPhrases = [];
    List<String> followUps = [];

    if (query.contains('introduce') || query.contains('giới thiệu')) {
      replyText =
          'To introduce yourself naturally, you can say: "Hello! My name is Nam. I am currently working as a software developer and I love learning new languages." Listen to how the sentence flows:';
      usefulPhrases = ['My name is...', 'I am currently working as...', 'In my spare time...'];
      followUps = ['How do I mention my hobbies?', 'What is a good phrase for job interviews?'];
    } else if (query.contains('restaurant') || query.contains('nhà hàng') || query.contains('gọi món')) {
      replyText =
          'When ordering food, a polite and native way is to say: "Could I please have the seafood pasta with a glass of water?" Here is how it sounds:';
      usefulPhrases = ['Could I please have...', 'What do you recommend?', 'Could I get the check?'];
      followUps = ['How do I ask if a dish is spicy?', 'How do I compliment the chef?'];
    } else if (query.contains('travel') || query.contains('du lịch') || query.contains('sân bay')) {
      replyText =
          'At the airport, you can ask the agent: "Excuse me, could you tell me where boarding gate 12 is located?" Listen to the intonation:';
      usefulPhrases = ['Where is gate...?', 'Is this flight on time?', 'Could I get a window seat?'];
      followUps = ['How do I report lost luggage?', 'How to ask for a taxi at the terminal?'];
    } else {
      replyText =
          'That is a very good question! Here is a natural way to express that in English: "I would be delighted to help you explore more conversational expressions." Listen to the native intonation:';
      usefulPhrases = ['I would be delighted to...', 'Feel free to ask...', 'Practice makes perfect.'];
      followUps = ['Tell me more about daily idioms.', 'How do I sound more natural?'];
    }

    return ChatMessage(
      id: 'ai_msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'ai',
      text: replyText,
      audioUrl: 'mock_audio_tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
      usefulPhrases: usefulPhrases,
      suggestedFollowUps: followUps,
      deliveryStatus: MessageDeliveryStatus.sent,
      timestamp: DateTime.now(),
    );
  }
}
