import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_failure.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/remote_chat_repository.dart';
import '../../data/speech_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/chat_repository.dart';
import '../../domain/models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (ref.watch(appConfigProvider).demoMode) return MockChatRepository();
  final accountId =
      ref.watch(authControllerProvider.select((s) => s.user?.id)) ?? '';
  return RemoteChatRepository(ref.watch(apiClientProvider),
      accountId: accountId,
      level:
          ref.watch(authControllerProvider.select((s) => s.user?.level.code)) ??
              'A1');
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

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatController(repo, isDemo: ref.watch(appConfigProvider).demoMode);
});

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final bool isDemo;
  final SpeechPlayer _speech = SpeechPlayer();
  final Map<String, String> _retryKeys = {};
  int _epoch = 0;
  int _audioEpoch = 0;
  bool _loading = false;
  bool _historyFailed = false;

  ChatController(this._repository, {this.isDemo = true})
      : super(ChatState(messages: [
          ChatMessage(
            id: 'welcome',
            role: 'ai',
            text:
                'Chào bạn! Hãy nhập câu hỏi hoặc câu tiếng Anh bạn muốn luyện tập.',
            timestamp: DateTime.now(),
          )
        ])) {
    if (_repository is RemoteChatRepository) unawaited(loadHistory());
  }

  Future<void> loadHistory() async {
    final repo = _repository;
    if (repo is! RemoteChatRepository || _loading) return;
    _loading = true;
    final epoch = _epoch;
    state = state.copyWith(isAiThinking: true);
    try {
      final messages = await repo.loadMessages();
      _historyFailed = false;
      if (!mounted || epoch != _epoch) return;
      state = state.copyWith(
          messages: messages.isEmpty ? state.messages : messages,
          isAiThinking: false);
    } catch (_) {
      _historyFailed = true;
      if (mounted && epoch == _epoch) {
        state = state.copyWith(
            isAiThinking: false,
            errorMessage:
                'Không tải được hội thoại. Hãy thử tải lại trước khi gửi.');
      }
      // Do not let a failed restore silently create a different session.
      return;
    } finally {
      _loading = false;
    }
  }

  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty ||
        state.isAiThinking ||
        _loading ||
        _historyFailed ||
        _retryKeys.isNotEmpty) {
      return;
    }
    if (trimmed.length > 4000) {
      state = state.copyWith(errorMessage: 'Mỗi tin nhắn tối đa 4000 ký tự.');
      return;
    }
    final key = ApiClient.newIdempotencyKey();
    final userMessage = ChatMessage(
        id: key,
        role: 'user',
        text: trimmed,
        deliveryStatus: MessageDeliveryStatus.sending,
        timestamp: DateTime.now());
    _retryKeys[userMessage.id] = key;
    state = state.copyWith(messages: [...state.messages, userMessage]);
    await _send(userMessage, key);
  }

  Future<void> retryMessage(String messageId) async {
    if (state.isAiThinking) return;
    final key = _retryKeys[messageId];
    if (key == null) return;
    final message = state.messages.where((m) => m.id == messageId).firstOrNull;
    if (message == null) return;
    await _send(message, key);
  }

  Future<void> _send(ChatMessage message, String key) async {
    final epoch = _epoch;
    state = state.copyWith(
        isAiThinking: true,
        messages: state.messages
            .map((m) => m.id == message.id
                ? m.copyWith(deliveryStatus: MessageDeliveryStatus.sending)
                : m)
            .toList());
    try {
      final response = await _repository.sendTextMessage(
          text: message.text, idempotencyKey: key);
      if (!mounted || epoch != _epoch) return;
      _retryKeys.remove(message.id);
      state = state.copyWith(messages: [
        ...state.messages.map((m) => m.id == message.id
            ? m.copyWith(deliveryStatus: MessageDeliveryStatus.sent)
            : m),
        response,
      ], isAiThinking: false);
    } catch (e) {
      if (!mounted || epoch != _epoch) return;
      state = state.copyWith(
          messages: state.messages
              .map((m) => m.id == message.id
                  ? m.copyWith(deliveryStatus: MessageDeliveryStatus.failed)
                  : m)
              .toList(),
          isAiThinking: false,
          errorMessage: e is ApiFailure
              ? e.message
              : 'Không kết nối được Tom. Hãy thử gửi lại tin nhắn.');
    }
  }

  Future<void> toggleAudioPlayback(String messageId) async {
    if (state.currentlyPlayingMessageId == messageId) {
      await stopAudio();
      return;
    }
    final message =
        state.messages.where((m) => m.id == messageId && m.isAi).firstOrNull;
    if (message == null) return;
    final epoch = ++_audioEpoch;
    state = state.copyWith(currentlyPlayingMessageId: messageId);
    try {
      await _speech.speak(message.text, state.globalPlaybackSpeed);
      if (mounted && epoch == _audioEpoch) {
        state = state.copyWith(currentlyPlayingMessageId: null);
      }
    } catch (_) {
      if (mounted && epoch == _audioEpoch) {
        state = state.copyWith(
            currentlyPlayingMessageId: null,
            errorMessage:
                'Không phát được giọng đọc trên thiết bị. Bạn vẫn có thể đọc nội dung.');
      }
    }
  }

  Future<void> stopAudio({bool updateState = true}) async {
    _audioEpoch++;
    if (mounted && updateState) {
      state = state.copyWith(currentlyPlayingMessageId: null);
    }
    try {
      await _speech.stop();
    } catch (_) {}
  }

  void setPlaybackSpeed(double speed) {
    if (![0.75, 1.0, 1.25].contains(speed)) return;
    final playing = state.currentlyPlayingMessageId;
    state = state.copyWith(globalPlaybackSpeed: speed);
    if (playing != null) unawaited(toggleAudioPlayback(playing));
  }

  Future<bool> beginScenario(String id, String level) async {
    if (state.isAiThinking || _retryKeys.isNotEmpty) return false;
    await clearChat();
    if (!mounted || state.errorMessage != null) return false;
    final repo = _repository;
    if (repo is RemoteChatRepository) {
      repo.scenarioId = id;
      repo.level = level;
    }
    return true;
  }

  Future<void> clearChat() async {
    if (state.isAiThinking) return;
    try {
      final repo = _repository;
      if (repo is RemoteChatRepository) await repo.completeSession();
      if (!mounted) return;
      _epoch++;
      _retryKeys.clear();
      await stopAudio();
      if (mounted) state = const ChatState();
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
            errorMessage:
                'Chưa kết thúc được phiên. Hội thoại vẫn được giữ lại.');
      }
    }
  }

  @override
  void dispose() {
    _epoch++;
    unawaited(stopAudio(updateState: false));
    super.dispose();
  }
}
