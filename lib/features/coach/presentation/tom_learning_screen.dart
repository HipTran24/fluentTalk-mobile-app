import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../connected/presentation/academic_widgets.dart';

final tomLearningProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(authControllerProvider.select((a) => a.user?.id));
  final api = ref.watch(apiClientProvider);
  if (api == null) {
    throw const ApiFailure(
        code: 'CONFIGURATION_REQUIRED', message: 'Chưa cấu hình máy chủ.');
  }
  final data = await api.get('me/learning');
  if (data is! Map<String, dynamic>) {
    throw const ApiFailure(
        code: 'INVALID_RESPONSE', message: 'Dữ liệu cá nhân hóa chưa hợp lệ.');
  }
  return data;
});
final tomTopicsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data =
      await ref.watch(apiClientProvider)?.get('topics', authenticated: false);
  return data is List ? data.whereType<Map<String, dynamic>>().toList() : [];
});

class TomLearningScreen extends ConsumerWidget {
  const TomLearningScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
            title: const Text('Tom · Lộ trình của bạn'), centerTitle: false),
        body: ref.watch(tomLearningProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                            error is ApiFailure
                                ? error.message
                                : 'Không tải được dữ liệu của Tom.',
                            textAlign: TextAlign.center),
                        TextButton(
                            onPressed: () =>
                                ref.invalidate(tomLearningProvider),
                            child: const Text('Thử lại'))
                      ]))),
              data: (data) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tomLearningProvider);
                    await ref.read(tomLearningProvider.future);
                  },
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const AcademicHeading(
                                      'Mỗi người học, một hành trình',
                                      'Tom dựa trên lựa chọn và dữ liệu học đã lưu của riêng bạn.'),
                                  _TomPreferences(
                                      key: ValueKey(
                                          '${ref.watch(authControllerProvider).user?.id}-${data['settings']}'),
                                      settings: Map<String, dynamic>.from(
                                          data['settings'] as Map? ?? {})),
                                  if ((data['settings'] as Map?)?['enabled'] ==
                                      true) ...[
                                    const AcademicHeading('Kế hoạch hôm nay',
                                        'Chỉ cộng phút từ phiên chat đã hoàn thành, theo múi giờ Việt Nam. Phụ đề cuộc gọi giúp Tom ghi nhớ nhưng chưa cộng vào thời gian này.'),
                                    AcademicPanel(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              '${data['todayMinutes']} / ${data['dailyMinutes']} phút',
                                              style: const TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 12),
                                          LinearProgressIndicator(
                                              value: ((data['todayMinutes']
                                                              as num? ??
                                                          0) /
                                                      (data['dailyMinutes']
                                                              as num? ??
                                                          15))
                                                  .clamp(0, 1)
                                                  .toDouble(),
                                              minHeight: 8,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          const SizedBox(height: 18),
                                          if ((data['plan'] as List? ?? [])
                                              .isEmpty)
                                            const Text(
                                                'Bạn đã đạt mục tiêu thời gian hôm nay. Hãy nghỉ ngơi hoặc ôn lại theo ý muốn.'),
                                          for (final step
                                              in (data['plan'] as List? ?? [])
                                                  .whereType<Map>())
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: Text(
                                                    '${step['minutes']} phút · ${step['title']}',
                                                    style: const TextStyle(
                                                        height: 1.6))),
                                        ])),
                                    const AcademicHeading(
                                        'Tình huống dành cho bạn',
                                        'Mỗi đề xuất đều có lý do từ hồ sơ và lịch sử của bạn.'),
                                    if ((data['recommendations'] as List? ?? [])
                                        .isEmpty)
                                      const Text(
                                          'Chưa có tình huống phù hợp trong danh mục hiện tại.'),
                                    for (final item
                                        in (data['recommendations'] as List? ??
                                                [])
                                            .whereType<Map>())
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: AcademicPanel(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text(
                                                    item['title'] as String? ??
                                                        '',
                                                    style: const TextStyle(
                                                        fontSize: 19,
                                                        fontWeight:
                                                            FontWeight.w800)),
                                                const SizedBox(height: 8),
                                                Text(
                                                    '${item['level']} · Khoảng ${item['minutes']} phút',
                                                    style: const TextStyle(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const SizedBox(height: 12),
                                                for (final reason
                                                    in item['reasons']
                                                            as List? ??
                                                        [])
                                                  Text('• $reason',
                                                      style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          height: 1.7)),
                                                const SizedBox(height: 16),
                                                FilledButton(
                                                    onPressed: () => context.push(
                                                        '/practice/scenario/${item['id']}'),
                                                    child: const Text(
                                                        'Mở tình huống')),
                                              ]))),
                                    const AcademicHeading(
                                        'Tom đang dựa trên điều gì?',
                                        'Dữ liệu gốc và giới hạn của đề xuất.'),
                                    AcademicPanel(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(data['basis'] as String? ?? '',
                                              style:
                                                  const TextStyle(height: 1.7)),
                                          const SizedBox(height: 12),
                                          Text(
                                              '${data['textSamples']} mẫu tin nhắn · ${data['voiceSamples']} phiên có phụ đề đã lưu',
                                              style: const TextStyle(
                                                  color: AppColors.textMuted)),
                                          for (final evidence
                                              in (data['evidence'] as List? ??
                                                      [])
                                                  .whereType<Map>())
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 18),
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          evidence['source'] ==
                                                                  'saved_text'
                                                              ? 'Tin nhắn đã lưu'
                                                              : 'Phụ đề cuộc gọi từ trình duyệt · có thể nhận dạng sai',
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              color: AppColors
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700)),
                                                      const SizedBox(height: 6),
                                                      SelectableText(
                                                          evidence['text']
                                                                  as String? ??
                                                              ''),
                                                      if (evidence['source'] ==
                                                          'saved_text')
                                                        TextButton(
                                                            onPressed: () =>
                                                                context.push(
                                                                    '/practice/session/${evidence['sessionId']}/summary'),
                                                            child: const Text(
                                                                'Xem nguồn hội thoại')),
                                                    ])),
                                        ])),
                                  ] else
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 24),
                                        child: Text(
                                            'Bật cá nhân hóa bên trên để Tom tạo đề xuất. Khi chưa bật, Tom không đọc lịch sử giữa các phiên để ghi nhớ.')),
                                ]))),
                  ])),
            ),
      );
}

class _TomPreferences extends ConsumerStatefulWidget {
  const _TomPreferences({super.key, required this.settings});
  final Map<String, dynamic> settings;
  @override
  ConsumerState<_TomPreferences> createState() => _TomPreferencesState();
}

class _TomPreferencesState extends ConsumerState<_TomPreferences> {
  late bool enabled, saveVoice;
  late String voice;
  String? topic;
  late final TextEditingController goal;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    enabled = widget.settings['enabled'] == true;
    saveVoice = widget.settings['saveVoiceTranscripts'] == true;
    voice = widget.settings['voice'] as String? ?? 'Aoede';
    topic = widget.settings['topicId'] as String?;
    goal = TextEditingController(
        text: widget.settings['goal'] as String? ?? 'Giao tiếp hằng ngày');
  }

  @override
  void dispose() {
    goal.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    if (goal.text.trim().isEmpty) {
      setState(() => error = 'Hãy nhập mục tiêu của bạn.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      if (api == null) throw StateError('Missing API');
      await api.patch('me/learning', data: {
        'enabled': enabled,
        'saveVoiceTranscripts': enabled && saveVoice,
        'goal': goal.text.trim(),
        'topicId': topic,
        'voice': voice
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu lựa chọn cho Tom.')));
      ref.invalidate(tomLearningProvider);
    } catch (e) {
      if (mounted) {
        setState(() =>
            error = e is ApiFailure ? e.message : 'Không lưu được lựa chọn.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(tomTopicsProvider);
    return AcademicPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Cá nhân hóa cùng Tom'),
          subtitle: const Text(
              'Dùng hồ sơ và lịch sử để chọn bài. Trích đoạn gần đây được gửi đến Google Gemini để Tom thích ứng khi trò chuyện.'),
          value: enabled,
          onChanged: busy ? null : (v) => setState(() => enabled = v)),
      const SizedBox(height: 16),
      TextField(
          controller: goal,
          maxLength: 100,
          enabled: !busy,
          decoration: const InputDecoration(
              labelText: 'Mục tiêu của bạn',
              hintText: 'Ví dụ: phỏng vấn xin việc bằng tiếng Anh',
              border: OutlineInputBorder())),
      const SizedBox(height: 16),
      topics.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text(
              'Chưa tải được chủ đề. Có thể lưu các lựa chọn còn lại.'),
          data: (items) => DropdownButtonFormField<String>(
              initialValue: topic ?? '',
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Chủ đề quan tâm', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Không ưu tiên chủ đề')),
                for (final t in items)
                  DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text(t['title'] as String? ?? ''))
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() => topic = v == '' ? null : v))),
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(
          initialValue: voice,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Giọng Tom mặc định', border: OutlineInputBorder()),
          items: ['Aoede', 'Kore', 'Puck', 'Charon']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: busy ? null : (v) => setState(() => voice = v ?? 'Aoede')),
      const SizedBox(height: 16),
      SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: saveVoice && enabled,
          onChanged:
              busy || !enabled ? null : (v) => setState(() => saveVoice = v),
          title: const Text('Cho Tom ghi nhớ phụ đề cuộc gọi'),
          subtitle: const Text(
              'Chỉ lưu phần bạn nói thành văn bản, tối đa 30 ngày. Không lưu audio. Tắt lựa chọn này hoặc tắt cá nhân hóa sẽ xóa phụ đề đã lưu.')),
      const SizedBox(height: 12),
      const Text(
          'Mục tiêu thời gian và trình độ được chỉnh trong Cá nhân. Đề xuất không phải đánh giá CEFR hay chẩn đoán điểm yếu.',
          style:
              TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.6)),
      if (error != null)
        Text(error!, style: const TextStyle(color: AppColors.error)),
      const SizedBox(height: 20),
      FilledButton(
          onPressed: busy ? null : save,
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(busy ? 'Đang lưu…' : 'Lưu cá nhân hóa'))),
      TextButton(
          onPressed: busy
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                              title: const Text('Xóa phụ đề Tom đã ghi nhớ?'),
                              content: const Text(
                                  'Phụ đề cuộc gọi đã lưu sẽ được xóa. Lịch sử chat vẫn giữ nguyên.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Hủy')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Xóa phụ đề'))
                              ]));
                  if (confirmed != true || !mounted) return;
                  setState(() => busy = true);
                  try {
                    await ref
                        .read(apiClientProvider)!
                        .delete('me/learning/voice-notes');
                    if (mounted) ref.invalidate(tomLearningProvider);
                  } catch (e) {
                    if (mounted) {
                      setState(() => error = e is ApiFailure
                          ? e.message
                          : 'Không xóa được phụ đề.');
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: const Text('Xóa phụ đề đã ghi nhớ')),
    ]));
  }
}
