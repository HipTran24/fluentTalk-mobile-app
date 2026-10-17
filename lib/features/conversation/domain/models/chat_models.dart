/// Chat Message Delivery Status
enum MessageDeliveryStatus {
  sending,
  sent,
  failed,
}

/// Rich Chat Message for Mode 1: Ask by Text, Hear AI
class ChatMessage {
  final String id;
  final String role; // 'user' or 'ai'
  final String text;
  final String? audioUrl;
  final bool isPlaying;
  final double playbackSpeed;
  final List<String> usefulPhrases;
  final List<String> suggestedFollowUps;
  final MessageDeliveryStatus deliveryStatus;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.audioUrl,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.usefulPhrases = const [],
    this.suggestedFollowUps = const [],
    this.deliveryStatus = MessageDeliveryStatus.sent,
    required this.timestamp,
  });

  bool get isUser => role == 'user';
  bool get isAi => role == 'ai';

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    String? audioUrl,
    bool? isPlaying,
    double? playbackSpeed,
    List<String>? usefulPhrases,
    List<String>? suggestedFollowUps,
    MessageDeliveryStatus? deliveryStatus,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      audioUrl: audioUrl ?? this.audioUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      usefulPhrases: usefulPhrases ?? this.usefulPhrases,
      suggestedFollowUps: suggestedFollowUps ?? this.suggestedFollowUps,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
