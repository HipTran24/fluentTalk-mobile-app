import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/chat_repository.dart';
import '../../domain/models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return MockChatRepository();
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isAiThinking;
  final String? currentlyPlayingMessageId;
  final double globalPlaybackSpeed;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isAiThinking = false,
    this.currentlyPlayingMessageId,
    this.globalPlaybackSpeed = 1.0,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isAiThinking,
    String? currentlyPlayingMessageId,
    double? globalPlaybackSpeed,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      currentlyPlayingMessageId: currentlyPlayingMessageId,
      globalPlaybackSpeed: globalPlaybackSpeed ?? this.globalPlaybackSpeed,
      errorMessage: errorMessage,
    );
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatController(repo);
});

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repository;

  ChatController(this._repository)
      : super(ChatState(
          messages: [
            ChatMessage(
              id: 'init_welcome_01',
              role: 'ai',
              text:
                  'Hello! Tôi là Coach Emma. Bạn có thể gõ bất kỳ câu hỏi hoặc mẫu câu nào bằng tiếng Anh hoặc tiếng Việt, tôi sẽ giải thích và phát âm chuẩn bản xứ cho bạn nghe.',
              audioUrl: 'welcome_audio.mp3',
              usefulPhrases: const ['How should I say...', 'Could you explain...', 'Give me an example...'],
              suggestedFollowUps: const [
                'Cách chào hỏi tự nhiên khi gặp người lạ?',
                'Mẫu câu gọi món nhà hàng hay dùng?',
                'Cách nói về sở thích bản thân?',
              ],
              deliveryStatus: MessageDeliveryStatus.sent,
              timestamp: DateTime.now(),
            ),
          ],
        ));

  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessageId = 'user_msg_${DateTime.now().millisecondsSinceEpoch}';
    final idempotencyKey = 'idemp_${DateTime.now().millisecondsSinceEpoch}_${trimmed.hashCode}';

    final userMessage = ChatMessage(
      id: userMessageId,
      role: 'user',
      text: trimmed,
      deliveryStatus: MessageDeliveryStatus.sent,
      timestamp: DateTime.now(),
    );

    // Append user message immediately
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isAiThinking: true,
      errorMessage: null,
    );

    try {
      final aiResponse = await _repository.sendTextMessage(
        text: trimmed,
        idempotencyKey: idempotencyKey,
      );

      state = state.copyWith(
        messages: [...state.messages, aiResponse],
        isAiThinking: false,
      );
    } catch (e) {
      // Mark user message as failed if upstream error occurs
      final updatedMessages = state.messages.map((m) {
        if (m.id == userMessageId) {
          return m.copyWith(deliveryStatus: MessageDeliveryStatus.failed);
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isAiThinking: false,
        errorMessage: 'Không thể kết nối đến gia sư AI. Vui lòng bấm thử lại.',
      );
    }
  }

  void toggleAudioPlayback(String messageId) {
    if (state.currentlyPlayingMessageId == messageId) {
      // Pause
      state = state.copyWith(currentlyPlayingMessageId: null);
    } else {
      // Play new
      state = state.copyWith(currentlyPlayingMessageId: messageId);
    }
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(globalPlaybackSpeed: speed);
  }

  void clearChat() {
    state = ChatState(
      messages: [
        ChatMessage(
          id: 'new_welcome_${DateTime.now().millisecondsSinceEpoch}',
          role: 'ai',
          text: 'Cuộc trò chuyện mới đã bắt đầu! Hãy gõ câu hỏi bạn muốn luyện nói nhé.',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
}
