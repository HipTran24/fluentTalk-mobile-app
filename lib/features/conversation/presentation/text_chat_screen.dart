import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import '../../../core/widgets/adaptive_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/models/chat_models.dart';
import 'controllers/chat_controller.dart';

/// Screen 10 — Mode 1: Ask Tom by Text, Hear Tom Reply
/// Compliant with ESP-PLAN-001 Appendix A4, B12 & MODE-01
class TextChatScreen extends ConsumerStatefulWidget {
  const TextChatScreen({super.key});

  @override
  ConsumerState<TextChatScreen> createState() => _TextChatScreenState();
}

class _TextChatScreenState extends ConsumerState<TextChatScreen>
    with WidgetsBindingObserver {
  ChatController? _chatController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chatController?.stopAudio();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _chatController?.stopAudio();
  }

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController?.stopAudio(updateState: false);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textOverride]) {
    final text = textOverride ?? _inputController.text.trim();
    final state = ref.read(chatControllerProvider);
    if (text.isEmpty ||
        state.isAiThinking ||
        state.messages
            .any((m) => m.deliveryStatus == MessageDeliveryStatus.failed)) {
      return;
    }

    if (text.length > 4000) {
      ref.read(chatControllerProvider.notifier).sendTextMessage(text);
      return;
    }
    ref.read(chatControllerProvider.notifier).sendTextMessage(text);
    _inputController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final chatController = ref.read(chatControllerProvider.notifier);
    _chatController = chatController;
    ref.listen(chatControllerProvider, (_, next) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trợ lý Tom',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'clear') {
                chatController.clearChat();
              } else if (val == 'switch_guided') {
                context.push('/practice/scenarios');
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'switch_guided',
                child: Row(
                  children: [
                    Icon(Icons.mic, size: 18),
                    SizedBox(width: 8),
                    Text('Chuyển sang Luyện nói theo lượt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Làm mới cuộc trò chuyện',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message List
            Expanded(
              child: ListView.builder(
                scrollCacheExtent: const ScrollCacheExtent.pixels(500),
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                itemCount: chatState.messages.length,
                itemBuilder: (ctx, idx) {
                  final message = chatState.messages[idx];
                  return message.isUser
                      ? _buildUserMessageBubble(message)
                      : _buildAiMessageBubble(
                          message, chatState, chatController);
                },
              ),
            ),

            // Tom Thinking / Voice Generating Indicator (Isolated GPU RepaintBoundary)
            if (chatState.isAiThinking)
              RepaintBoundary(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: const AdaptiveRow(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Tom đang xử lý hội thoại…',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),

            if (chatState.errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(children: [
                  Text(chatState.errorMessage!,
                      style: const TextStyle(color: AppColors.error)),
                  if (!chatState.messages.any(
                      (m) => m.deliveryStatus == MessageDeliveryStatus.failed))
                    TextButton(
                        onPressed: () => chatController.loadHistory(),
                        child: const Text('Tải lại hội thoại')),
                ]),
              ),
            // Input Composer Bar
            _buildComposer(chatState),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessageBubble(ChatMessage message) {
    final isFailed = message.deliveryStatus == MessageDeliveryStatus.failed;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isFailed)
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppColors.error, size: 20),
                  onPressed: () => ref
                      .read(chatControllerProvider.notifier)
                      .retryMessage(message.id),
                  tooltip: 'Gửi lại tin nhắn',
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isFailed ? AppColors.errorBg : AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(AppRadius.lg),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isFailed ? AppColors.error : Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (isFailed)
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 4),
              child: Text(
                'Lỗi gửi tin nhắn. Chạm để thử lại.',
                style: TextStyle(fontSize: 11, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiMessageBubble(
    ChatMessage message,
    ChatState chatState,
    ChatController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach Avatar
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondaryLight,
            child: Icon(Icons.psychology, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                      bottomRight: Radius.circular(AppRadius.lg),
                    ),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reply Text
                      Text(
                        message.text,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                controller.toggleAudioPlayback(message.id),
                            icon: Icon(chatState.currentlyPlayingMessageId ==
                                    message.id
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded),
                            label: Text(chatState.currentlyPlayingMessageId ==
                                    message.id
                                ? 'Dừng đọc'
                                : 'Nghe / phát lại'),
                          ),
                          TextButton(
                            onPressed: () => controller.setPlaybackSpeed(
                                chatState.globalPlaybackSpeed == 1.0
                                    ? 0.75
                                    : chatState.globalPlaybackSpeed == 0.75
                                        ? 1.25
                                        : 1.0),
                            child: Text('${chatState.globalPlaybackSpeed}x'),
                          ),
                        ],
                      ),

                      // Useful Phrases Highlight
                      if (message.usefulPhrases.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Mẫu câu gợi ý:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: message.usefulPhrases.map((phrase) {
                            return InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: phrase));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã sao chép: "$phrase"'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              borderRadius:
                                  BorderRadius.circular(AppRadius.round),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.round),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2)),
                                ),
                                child: AdaptiveRow(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.copy,
                                        size: 11, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      phrase,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Suggested Follow-up Questions Chips
                if (message.suggestedFollowUps.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: message.suggestedFollowUps.map((question) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            avatar: const Icon(Icons.chat_bubble_outline,
                                size: 14, color: AppColors.accent),
                            label: Text(
                              question,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textPrimary),
                            ),
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () => _sendMessage(question),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Switch to Voice Practice Button
          IconButton(
            icon: const Icon(Icons.mic_none_rounded, color: AppColors.accent),
            tooltip: 'Chuyển sang chế độ luyện nói (Guided)',
            onPressed: () => context.push('/practice/scenarios'),
          ),

          // Text Field Multiline
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi tiếng Anh hoặc Việt...',
                  hintStyle:
                      TextStyle(fontSize: 14, color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Send Button with Double-submit protection
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            icon: chatState.isAiThinking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            onPressed: chatState.isAiThinking ? null : () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}
