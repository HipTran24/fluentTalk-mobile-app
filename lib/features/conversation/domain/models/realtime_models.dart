/// Speaker status in Realtime Call Mode
enum RealtimeSpeakerState {
  connecting,
  listening, // Tom is listening to user
  userSpeaking, // User is actively talking
  aiThinking, // Tom is processing response
  aiSpeaking, // Tom is talking (TTS)
  ended,
}

/// Live caption dialogue item
class RealtimeCaptionItem {
  final String id;
  final String speaker; // 'ai' or 'user'
  final String text;
  final DateTime timestamp;

  const RealtimeCaptionItem({
    required this.id,
    required this.speaker,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => speaker == 'user';
  bool get isAi => speaker == 'ai';
}

/// Helpful conversation prompt if learner gets stuck
class ConversationTopicHint {
  final String title;
  final String englishPhrase;
  final String vietnameseMeaning;

  const ConversationTopicHint({
    required this.title,
    required this.englishPhrase,
    required this.vietnameseMeaning,
  });
}
