import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import 'academic_widgets.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/network/api_failure.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

final connectedResourceProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, path) async {
  ref.watch(authControllerProvider.select((state) => state.user?.id));
  final api = ref.watch(apiClientProvider);
  if (api == null) {
    throw const ApiFailure(
        code: 'CONFIGURATION_REQUIRED', message: 'Chưa cấu hình máy chủ.');
  }
  final data = await api.get(path);
  if (data is! Map<String, dynamic>) {
    throw const ApiFailure(
        code: 'INVALID_RESPONSE', message: 'Dữ liệu máy chủ chưa hợp lệ.');
  }
  return data;
});

/// Real-account surfaces read only persisted backend data, never demo metrics.
class ConnectedAreaScreen extends ConsumerWidget {
  final String section;
  const ConnectedAreaScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titles = {
      'home': 'Trang chủ',
      'practice': 'Luyện tập',
      'progress': 'Tiến độ',
      'coach': 'Tom',
      'profile': 'Cá nhân',
      'history': 'Lịch sử luyện tập'
    };
    final path = section == 'profile'
        ? 'me'
        : section == 'history'
            ? 'sessions'
            : 'progress/summary';
    final resource = ref.watch(connectedResourceProvider(path));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 78,
        backgroundColor: const Color(0xFFF5F7FB),
        title: section == 'home'
            ? const Row(children: [
                AppLogo(size: 36, withShadow: false),
                SizedBox(width: 12),
                Expanded(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FluentTalk',
                                  style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.6)),
                              SizedBox(height: 4),
                              Text('ACADEMY',
                                  style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 2,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w700)),
                            ]))),
              ])
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titles[section] ?? 'FluentTalk',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      const Text('FLUENTTALK ACADEMY',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 2,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700)),
                    ])),
        actions: const [
          Padding(
              padding: EdgeInsets.only(right: 24),
              child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.school_outlined, color: AppColors.primary)))
        ],
      ),
      body: SafeArea(
          child: resource.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        error is ApiFailure
                            ? error.message
                            : 'Không tải được dữ liệu. Vui lòng thử lại.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () =>
                            ref.invalidate(connectedResourceProvider(path)),
                        child: const Text('Thử lại')),
                  ],
                ))),
        data: (data) {
          if (section == 'profile') {
            return _ProfileForm(key: ValueKey(data['id']), profile: data);
          }
          if (section == 'history') {
            final items = data['items'] is List ? data['items'] as List : [];
            return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(connectedResourceProvider(path)),
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  if (items.isEmpty)
                    const AcademicPanel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Icon(Icons.history_edu_outlined,
                              size: 40, color: AppColors.primary),
                          SizedBox(height: 20),
                          Text('Hành trình bắt đầu từ đây',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          SizedBox(height: 12),
                          Text(
                              'Chưa có phiên luyện tập. Bắt đầu một cuộc trò chuyện để lưu lịch sử.',
                              style: TextStyle(
                                  color: AppColors.textSecondary, height: 1.7)),
                        ])),
                  for (final item in items.whereType<Map<String, dynamic>>())
                    Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          leading: const CircleAvatar(
                              backgroundColor: AppColors.secondaryLight,
                              child: Icon(Icons.forum_outlined,
                                  color: AppColors.primary)),
                          title: Text(item['status'] == 'completed'
                              ? 'Phiên đã hoàn thành'
                              : 'Phiên đang luyện tập'),
                          subtitle: Text(_date(item['startedAt'])),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context
                              .push('/practice/session/${item['id']}/summary'),
                        )),
                  if (data['hasMore'] == true)
                    const Text('Đang hiển thị các phiên gần nhất.'),
                ]));
          }
          final name =
              ref.watch(authControllerProvider).user?.displayName ?? 'bạn';
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(connectedResourceProvider(path)),
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (section == 'home') ...[
                                  const SizedBox(height: 8),
                                  Text('Chào $name,',
                                      style: const TextStyle(
                                          fontSize: 27,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -.7)),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Mỗi cuộc trò chuyện là một bước tiến mới.',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          height: 1.5)),
                                  const SizedBox(height: 24),
                                ],
                                if (section == 'practice')
                                  AcademicHero(
                                      title: section == 'home'
                                          ? 'Tự tin hơn.\nTừng cuộc hội thoại.'
                                          : 'Biến kiến thức\nthành phản xạ.',
                                      subtitle:
                                          'Luyện nói với Tom, diễn đạt theo cách của bạn và khám phá tiếng Anh qua những tình huống thực tế.',
                                      onStart: () =>
                                          context.push('/practice/voice')),
                                if (section == 'home' ||
                                    section == 'progress') ...[
                                  AcademicHeading(
                                      section == 'progress'
                                          ? 'Hành trình của bạn'
                                          : 'Dấu ấn học tập',
                                      'Nhìn lại những gì bạn đã hoàn thành.'),
                                  AcademicGrid(minWidth: 220, children: [
                                    _metric(
                                        'Phiên đã hoàn thành',
                                        '${data['totalSessions'] ?? 0}',
                                        Icons.check_circle_outline,
                                        AppColors.primary),
                                    _metric(
                                        'Tổng thời gian luyện tập',
                                        '${data['totalMinutes'] ?? 0} phút',
                                        Icons.schedule_outlined,
                                        AppColors.accent),
                                    _metric(
                                        'Chuỗi ngày luyện tập',
                                        '${data['currentStreakDays'] ?? 0} ngày',
                                        Icons.local_fire_department_outlined,
                                        const Color(0xFFC07A35)),
                                  ]),
                                ],
                                if (section == 'home') ...[
                                  const AcademicHeading(
                                      'Sẵn sàng cho buổi học mới?',
                                      'Chọn chế độ luyện tập và bắt đầu theo nhịp của bạn.'),
                                  AcademicPanel(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        const Icon(Icons.auto_stories_outlined,
                                            color: AppColors.primary, size: 32),
                                        const SizedBox(height: 16),
                                        const Text(
                                            'Một nơi cho mọi hoạt động luyện tập',
                                            style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 10),
                                        const Text(
                                            'Hội thoại giọng nói, chat và tình huống thực tế đều nằm trong Luyện tập.',
                                            style: TextStyle(
                                                color: AppColors.textSecondary,
                                                height: 1.7)),
                                        const SizedBox(height: 20),
                                        FilledButton.icon(
                                            onPressed: () =>
                                                context.go('/practice'),
                                            icon: const Icon(
                                                Icons.arrow_forward_rounded),
                                            label: const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: Text(
                                                    'Mở không gian luyện tập'))),
                                      ])),
                                ],
                                if (section == 'coach') ...[
                                  const AcademicHeading('Học có định hướng',
                                      'Xây dựng sự tự tin từ những cuộc hội thoại mỗi ngày.'),
                                  const AcademicPanel(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Icon(Icons.psychology_outlined,
                                            size: 36, color: AppColors.primary),
                                        SizedBox(height: 16),
                                        Text('Coach cá nhân hóa chưa sẵn sàng',
                                            style: TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.w800)),
                                        SizedBox(height: 10),
                                        Text(
                                            'Lộ trình cá nhân sẽ cần đánh giá từ các phiên học thật. Trong lúc chờ, bạn có thể luyện hội thoại và xem lại những phiên đã lưu.',
                                            style: TextStyle(
                                                color: AppColors.textSecondary,
                                                height: 1.7)),
                                      ])),
                                ],
                                if (section == 'practice') ...[
                                  const AcademicHeading('Không gian luyện tập',
                                      'Chọn cách thực hành phù hợp với bạn.'),
                                  AcademicGrid(minWidth: 280, children: [
                                    AcademicAction(
                                        title: 'Luyện chat với Tom',
                                        description:
                                            'Sắp xếp ý tưởng, luyện cách diễn đạt và trò chuyện theo nhịp riêng của bạn.',
                                        icon: Icons.forum_outlined,
                                        tag: 'CONVERSATION',
                                        onTap: () =>
                                            context.push('/practice/text')),
                                    AcademicAction(
                                        title: 'Khám phá tình huống',
                                        description:
                                            'Đặt tiếng Anh vào ngữ cảnh: công việc, cuộc sống và những cuộc gặp gỡ.',
                                        icon: Icons.auto_stories_outlined,
                                        tag: 'REAL-WORLD ENGLISH',
                                        color: AppColors.accent,
                                        onTap: () => context
                                            .push('/practice/scenarios')),
                                  ]),
                                ],
                                if (section == 'progress') ...[
                                  const AcademicHeading('Ôn lại để tiến bộ',
                                      'Xem lại những cuộc hội thoại đã lưu.'),
                                  AcademicAction(
                                      title: 'Lịch sử hội thoại',
                                      description:
                                          'Mở lại các phiên đã lưu để đọc, suy ngẫm và củng cố cách diễn đạt.',
                                      icon: Icons.history_edu_outlined,
                                      tag: 'REFLECTION',
                                      color: const Color(0xFFA16E36),
                                      onTap: () =>
                                          context.push('/progress/history')),
                                ],
                                const SizedBox(height: 24),
                                if (section == 'practice' ||
                                    section == 'progress')
                                  AcademicPanel(
                                      padding: 20,
                                      child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                                Icons.lightbulb_outline_rounded,
                                                color: AppColors.accent,
                                                size: 22),
                                            const SizedBox(width: 14),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  const Text('Học đều, tiến xa',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800)),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                      section == 'progress'
                                                          ? 'Thống kê dựa trên phiên đã lưu. Chưa có điểm năng lực hay đánh giá CEFR chính thức; cuộc gọi Live hiện chưa cộng vào thống kê.'
                                                          : 'Dành một khoảng thời gian ngắn mỗi ngày. Khi luyện nói, hãy dùng tai nghe và cho bản thân thời gian suy nghĩ.',
                                                      style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 13,
                                                          height: 1.6)),
                                                ])),
                                          ])),
                              ]))),
                ]),
          );
        },
      )),
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) =>
      AcademicPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 20),
        Text(value,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.7)),
        const SizedBox(height: 8),
        Text(title,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12, height: 1.5)),
      ]));

  static String _date(Object? value) {
    final date = DateTime.tryParse(value is String ? value : '')?.toLocal();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final Map<String, dynamic> profile;
  const _ProfileForm({super.key, required this.profile});
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController name;
  late String level;
  late int minutes;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(
        text: widget.profile['displayName'] as String? ?? '');
    level = widget.profile['level'] as String? ?? 'A1';
    minutes = widget.profile['dailyMinutes'] as int? ?? 15;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    if (name.text.trim().isEmpty || name.text.trim().length > 100) {
      setState(() => error = 'Tên hiển thị cần từ 1 đến 100 ký tự.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      if (api == null) throw StateError('Missing backend');
      await api.patch('me', data: {
        'displayName': name.text.trim(),
        'level': level,
        'dailyMinutes': minutes,
        'onboarded': true
      });
      if (!mounted) return;
      await ref.read(authControllerProvider.notifier).syncProfileFromBackend();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hồ sơ lên máy chủ.')));
    } catch (e) {
      if (mounted) {
        setState(() => error =
            e is ApiFailure ? e.message : 'Không lưu được hồ sơ. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), children: [
        Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AcademicPanel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                    color: AppColors.secondaryLight,
                                    borderRadius: BorderRadius.circular(22)),
                                child: const Icon(Icons.person_outline_rounded,
                                    color: AppColors.primary, size: 36)),
                            const SizedBox(height: 20),
                            Text(
                                widget.profile['displayName'] as String? ??
                                    'Hồ sơ học viên',
                                style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.6)),
                            const SizedBox(height: 8),
                            Text(widget.profile['email'] as String? ?? '',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.6)),
                          ])),
                      const AcademicHeading('Hồ sơ học tập',
                          'Thiết lập mục tiêu phù hợp với nhịp sống của bạn.'),
                      AcademicPanel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            const Text('Thông tin cá nhân',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 17)),
                            const SizedBox(height: 22),
                            TextField(
                                controller: name,
                                maxLength: 100,
                                decoration: const InputDecoration(
                                    labelText: 'Tên hiển thị',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                                initialValue: level,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Trình độ tự chọn',
                                    prefixIcon: Icon(Icons.school_outlined),
                                    border: OutlineInputBorder()),
                                items: UserLevel.values
                                    .map((item) => DropdownMenuItem(
                                        value: item.code,
                                        child: Text(item.code)))
                                    .toList(),
                                onChanged: saving
                                    ? null
                                    : (value) =>
                                        setState(() => level = value ?? 'A1')),
                            const SizedBox(height: 12),
                            const Text(
                                'Đây là lựa chọn cá nhân, chưa phải kết quả đánh giá CEFR chính thức.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    height: 1.6)),
                            const SizedBox(height: 28),
                            const Divider(),
                            const SizedBox(height: 18),
                            Text('Mục tiêu: $minutes phút/ngày',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 17)),
                            const SizedBox(height: 8),
                            const Text(
                                'Giữ một nhịp học đều đặn, vừa sức mỗi ngày.',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                            Slider(
                                value: minutes.clamp(5, 60).toDouble(),
                                min: 5,
                                max: 60,
                                divisions: 11,
                                label: '$minutes phút',
                                onChanged: saving
                                    ? null
                                    : (value) => setState(
                                        () => minutes = value.round())),
                            if (error != null)
                              Text(error!,
                                  style:
                                      const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                                onPressed: saving ? null : save,
                                icon: const Icon(Icons.check_rounded),
                                label: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                        saving ? 'Đang lưu…' : 'Lưu hồ sơ'))),
                          ])),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text('Đăng xuất'))),
                    ]))),
      ]);
}

class ConnectedSessionScreen extends ConsumerWidget {
  final String sessionId;
  const ConnectedSessionScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = 'sessions/$sessionId';
    final resource = ref.watch(connectedResourceProvider(path));
    return Scaffold(
        appBar: AppBar(title: const Text('Hội thoại đã lưu')),
        body: SafeArea(
            child: resource.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
              child: TextButton(
                  onPressed: () =>
                      ref.invalidate(connectedResourceProvider(path)),
                  child: const Text('Không tải được hội thoại. Thử lại'))),
          data: (data) {
            final messages =
                data['messages'] is List ? data['messages'] as List : [];
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text(data['status'] == 'completed'
                  ? 'Phiên đã hoàn thành'
                  : 'Phiên đang luyện tập'),
              const SizedBox(height: 12),
              if (messages.isEmpty)
                const Text('Chưa có tin nhắn trong phiên này.'),
              for (final message in messages.whereType<Map<String, dynamic>>())
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message['role'] == 'user' ? 'Bạn' : 'Tom',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              SelectableText(message['text'] as String? ?? ''),
                            ]))),
              const SizedBox(height: 12),
              const Text(
                  'Chưa có đánh giá năng lực được kiểm chứng cho phiên này.'),
            ]);
          },
        )));
  }
}
