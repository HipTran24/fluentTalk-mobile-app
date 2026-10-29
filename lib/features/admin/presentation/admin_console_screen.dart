import 'usage_dashboard.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../connected/presentation/academic_widgets.dart';

final adminDataProvider = FutureProvider.autoDispose
    .family<Object?, ({String path, String q, int page, String filter})>(
        (ref, key) async {
  ref.watch(authControllerProvider.select((a) => a.user?.id));
  final api = ref.watch(apiClientProvider);
  if (api == null) {
    throw const ApiFailure(
        code: 'CONFIGURATION_REQUIRED', message: 'Chưa cấu hình máy chủ.');
  }
  return api.get('admin/${key.path}', query: {
    if (key.path == 'learners' || key.path == 'scenarios') 'q': key.q,
    if (['learners', 'scenarios', 'audit'].contains(key.path)) ...{
      'page': key.page,
      'size': 20
    },
    if (key.path == 'usage') ...{
      'days': int.tryParse(key.q) ?? 7,
      'provider': key.filter
    },
    if (key.path == 'learners' && key.filter.isNotEmpty) 'level': key.filter,
    if (key.path == 'scenarios' && key.filter.isNotEmpty)
      'active': key.filter == 'active'
  });
});

final adminTopicsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authControllerProvider.select((a) => a.user?.id));
  final data = await ref.watch(apiClientProvider)!.get('admin/topics');
  return (data as List).whereType<Map<String, dynamic>>().toList();
});

/// Dedicated Dark Theme specifically tuned for the FluentTalk Admin Console
final ThemeData _adminDarkTheme = AppTheme.darkTheme.copyWith(
  scaffoldBackgroundColor: const Color(0xFF090D16),
  canvasColor: const Color(0xFF0D121F),
  cardColor: const Color(0xFF131B2E),
  dividerColor: const Color(0xFF1E293B),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6366F1),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1E1B4B),
    onPrimaryContainer: Color(0xFFC7D2FE),
    secondary: Color(0xFF06B6D4),
    onSecondary: Colors.white,
    surface: Color(0xFF131B2E),
    onSurface: Color(0xFFF8FAFC),
    outline: Color(0xFF334155),
    outlineVariant: Color(0xFF1E293B),
    error: Color(0xFFF43F5E),
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D121F),
    foregroundColor: Color(0xFFF8FAFC),
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Color(0xFFF8FAFC),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF0D121F),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
    helperStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF334155)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF334155)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
    ),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: Color(0xFF6366F1),
    thumbColor: Color(0xFF818CF8),
    inactiveTrackColor: Color(0xFF1E293B),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? const Color(0xFF6366F1)
            : const Color(0xFF94A3B8)),
    trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? const Color(0xFF312E81)
            : const Color(0xFF1E293B)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFCBD5E1),
      side: const BorderSide(color: Color(0xFF334155), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF818CF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF0F172A),
    elevation: 16,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFF1E293B)),
    ),
  ),
);

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({super.key});
  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends ConsumerState<AdminConsoleScreen> {
  static const sections = [
    ('Tổng quan', Icons.dashboard_outlined, 'summary'),
    ('Học viên', Icons.people_outline, 'learners'),
    ('Tình huống', Icons.auto_stories_outlined, 'scenarios'),
    ('Chủ đề', Icons.category_outlined, 'topics'),
    ('Nhật ký', Icons.history_outlined, 'audit'),
    ('Dịch vụ', Icons.settings_outlined, 'services'),
    ('Sử dụng', Icons.bar_chart_outlined, 'usage')
  ];

  int tab = 0, page = 0, usageDays = 7;
  String query = '', filter = '';
  bool busy = false;
  final search = TextEditingController();
  Timer? debounce;

  ({String path, String q, int page, String filter}) get key => (
        path: sections[tab].$3,
        q: tab == 6 ? '$usageDays' : query,
        page: page,
        filter: filter
      );

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void select(int value) {
    debounce?.cancel();
    search.clear();
    setState(() {
      tab = value;
      page = 0;
      query = '';
      filter = '';
    });
  }

  void refresh() {
    ref.invalidate(adminDataProvider(key));
    ref.invalidate(adminTopicsProvider);
  }

  static String id() {
    final h = ApiClient.newIdempotencyKey().substring(0, 32);
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> save(String path, Map<String, dynamic> data,
      {bool patch = false, String? method}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final api = ref.read(apiClientProvider)!;
      await api.request(method ?? (patch ? 'PATCH' : 'PUT'), 'admin/$path',
          data: data);
      if (!mounted) return;
      refresh();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu thay đổi.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> editLearner(Map<String, dynamic> item) async {
    final name =
        TextEditingController(text: item['displayName'] as String? ?? '');
    String level = item['level'] as String? ?? 'A1';
    int minutes = (item['dailyMinutes'] as num? ?? 15).toInt();
    bool suspended = item['suspended'] == true;
    await editor(
        'Hồ sơ học viên',
        (update, working) => [
              Text(item['email'] as String? ?? '',
                  style: const TextStyle(color: Color(0xFF94A3B8))),
              const SizedBox(height: 16),
              TextFormField(
                  controller: name,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nhập tên học viên'
                      : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                  initialValue: level,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration:
                      const InputDecoration(labelText: 'Trình độ tự chọn'),
                  items: levels
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged:
                      working ? null : (v) => update(() => level = v ?? level)),
              const SizedBox(height: 16),
              Text('Mục tiêu: $minutes phút/ngày',
                  style: const TextStyle(
                      color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600)),
              Slider(
                  value: minutes.clamp(5, 60).toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: working
                      ? null
                      : (v) => update(() => minutes = v.round())),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tạm khóa quyền sử dụng app',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Không xóa tài khoản hoặc dữ liệu. Tài khoản bị khóa vẫn có thể xác thực email nhưng sẽ bị chặn API. Cuộc gọi Live đã mở có thể tiếp tục đến khi token hết hạn (tối đa 5 phút).',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                  value: suspended,
                  onChanged:
                      working ? null : (v) => update(() => suspended = v)),
            ],
        () => save(
            'learners/${item['id']}',
            {
              'displayName': name.text.trim(),
              'level': level,
              'dailyMinutes': minutes,
              'suspended': suspended,
              'revision': item['revision']
            },
            patch: true));
    name.dispose();
  }

  static const levels = ['A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  Future<void> editScenario([Map<String, dynamic>? item]) async {
    List<Map<String, dynamic>> topics;
    try {
      topics = await ref.read(adminTopicsProvider.future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Chưa tải được chủ đề. Hãy thử lại.')));
      }
      return;
    }
    if (!mounted) return;
    if (topics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Hãy tạo chủ đề trước khi thêm tình huống.')));
      return;
    }
    final values = {
      for (final field in ['title', 'description', 'aiRole', 'userRole'])
        field: TextEditingController(text: item?[field] as String? ?? '')
    };
    final phrases = TextEditingController(
        text: (item?['samplePhrases'] as List? ?? []).join('\n'));
    final objectives = TextEditingController(
        text: (item?['learningObjectives'] as List? ?? []).join('\n'));
    String level = item?['level'] as String? ?? 'A1',
        topic = item?['topicId'] as String? ?? topics.first['id'] as String;
    int minutes = (item?['estimatedMinutes'] as num? ?? 10).toInt();
    bool active = item?['active'] == true;
    final scenarioId = item?['id'] as String? ?? id();
    await editor(
        item == null ? 'Thêm tình huống' : 'Chỉnh sửa tình huống',
        (update, working) => [
              for (final field in [
                'title',
                'description',
                'aiRole',
                'userRole'
              ])
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                        controller: values[field],
                        maxLength: field == 'description'
                            ? 4000
                            : field == 'title'
                                ? 150
                                : 100,
                        maxLines: field == 'description' ? 3 : 1,
                        decoration: InputDecoration(
                            labelText: {
                          'title': 'Tên tình huống',
                          'description': 'Bối cảnh và mô tả',
                          'aiRole': 'Vai trò của Tom',
                          'userRole': 'Vai trò người học'
                        }[field]),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng điền nội dung'
                            : null)),
              DropdownButtonFormField<String>(
                  initialValue: topic,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration: const InputDecoration(labelText: 'Chủ đề'),
                  items: topics
                      .map((t) => DropdownMenuItem(
                          value: t['id'] as String,
                          child: Text(t['title'] as String)))
                      .toList(),
                  onChanged:
                      working ? null : (v) => update(() => topic = v ?? topic)),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                  initialValue: level,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration: const InputDecoration(labelText: 'Trình độ'),
                  items: levels
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged:
                      working ? null : (v) => update(() => level = v ?? level)),
              const SizedBox(height: 18),
              Text('Thời lượng dự kiến: $minutes phút',
                  style: const TextStyle(
                      color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600)),
              Slider(
                  value: minutes.clamp(1, 60).toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  onChanged: working
                      ? null
                      : (v) => update(() => minutes = v.round())),
              TextFormField(
                  controller: phrases,
                  maxLines: 4,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                      labelText: 'Mẫu câu · mỗi dòng một câu'),
                  validator: validateLines),
              const SizedBox(height: 16),
              TextFormField(
                  controller: objectives,
                  maxLines: 3,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                      labelText: 'Mục tiêu bài học · mỗi dòng một mục'),
                  validator: validateLines),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Xuất bản trong danh mục',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Tắt để ẩn khỏi danh mục học viên; lịch sử cũ được giữ nguyên.',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                  value: active,
                  onChanged: working ? null : (v) => update(() => active = v)),
            ],
        () => save('scenarios/$scenarioId', {
              'title': values['title']!.text.trim(),
              'description': values['description']!.text.trim(),
              'aiRole': values['aiRole']!.text.trim(),
              'userRole': values['userRole']!.text.trim(),
              'topicId': topic,
              'level': level,
              'estimatedMinutes': minutes,
              'active': active,
              'samplePhrases': lines(phrases.text),
              'learningObjectives': lines(objectives.text),
              'revision': item?['revision']
            }));
    for (final c in values.values) {
      c.dispose();
    }
    phrases.dispose();
    objectives.dispose();
  }

  static List<String> lines(String text) =>
      text.split('\n').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
  static String? validateLines(String? value) {
    final list = lines(value ?? '');
    return list.length > 20 || list.any((v) => v.length > 200)
        ? 'Tối đa 20 dòng, mỗi dòng 200 ký tự.'
        : null;
  }

  Future<void> editTopic([Map<String, dynamic>? item]) async {
    final title = TextEditingController(text: item?['title'] as String? ?? '');
    final slug = TextEditingController(text: item?['slug'] as String? ?? '');
    final topicId = item?['id'] as String? ?? id();
    await editor(
        item == null ? 'Thêm chủ đề' : 'Chỉnh sửa chủ đề',
        (_, __) => [
              TextFormField(
                  controller: title,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Tên chủ đề'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nhập tên chủ đề' : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: slug,
                  maxLength: 50,
                  decoration: const InputDecoration(
                      labelText: 'Mã chủ đề', hintText: 'vi-du-chu-de'),
                  validator: (v) =>
                      RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(v ?? '')
                          ? null
                          : 'Chỉ dùng chữ thường, số và dấu gạch nối.'),
            ],
        () => save('topics/$topicId',
            {'title': title.text.trim(), 'slug': slug.text.trim()}));
    title.dispose();
    slug.dispose();
  }

  Future<void> editProvider(String channel, Map<String, dynamic> config) async {
    final model = TextEditingController(text: config['model'] as String? ?? '');
    final secret = TextEditingController();
    String provider = config['provider'] as String? ?? 'gemini';
    Map<String, dynamic> payload() => {
          'provider': provider,
          'model': model.text.trim(),
          'apiKey': secret.text.trim(),
          'revision': config['revision']
        };
    await editor(
      channel == 'text' ? 'Cấu hình chat Tom' : 'Cấu hình giọng nói Live',
      (update, working) => [
        const Text(
            'Áp dụng cho yêu cầu mới ngay sau khi lưu. Cuộc gọi đang mở giữ cấu hình cũ đến khi kết thúc.',
            style: TextStyle(color: Color(0xFF94A3B8))),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: provider,
          isExpanded: true,
          dropdownColor: const Color(0xFF0F172A),
          decoration: const InputDecoration(labelText: 'Provider'),
          items: (channel == 'text' ? ['gemini', 'openai', 'groq'] : ['gemini'])
              .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text({
                    'gemini': 'Google Gemini',
                    'openai': 'OpenAI',
                    'groq': 'Groq'
                  }[v]!)))
              .toList(),
          onChanged: working
              ? null
              : (v) => update(() {
                    provider = v!;
                    model.clear();
                    secret.clear();
                  }),
        ),
        const SizedBox(height: 20),
        TextFormField(
            controller: model,
            enabled: !working,
            maxLength: 100,
            decoration: const InputDecoration(
                labelText: 'Model ID',
                helperText: 'Nhập model được cấp quyền tại provider.',
                helperMaxLines: 3),
            validator: (v) => RegExp(r'^[A-Za-z0-9][A-Za-z0-9._/-]{0,99}$')
                    .hasMatch(v?.trim() ?? '')
                ? null
                : 'Nhập model ID hợp lệ.'),
        const SizedBox(height: 16),
        TextFormField(
            controller: secret,
            enabled: !working,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 3000,
            decoration: InputDecoration(
                labelText: 'API key mới',
                helperText: provider == config['provider'] &&
                        config['keyConfigured'] == true
                    ? 'Để trống để giữ key hiện tại. Key đã lưu không được hiển thị lại.'
                    : 'Cần key của provider được chọn.',
                helperMaxLines: 4),
            validator: (v) => (v?.trim().isEmpty ?? true) &&
                    (provider != config['provider'] ||
                        config['keyConfigured'] != true)
                ? 'Nhập API key.'
                : null),
        const SizedBox(height: 16),
        Text(
          channel == 'text'
              ? 'Chọn model chat hỗ trợ JSON. Nút kiểm tra gửi một câu chào thử, có thể tính phí theo provider.'
              : 'Live hiện hỗ trợ Gemini. Kiểm tra chỉ cấp phiên ngắn hạn, chưa kiểm tra âm thanh trình duyệt.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      ],
      () => save('providers/$channel', payload()),
      check: () async {
        final result = await ref.read(apiClientProvider)!.request(
            'POST', 'admin/providers/$channel/check',
            data: payload()) as Map;
        return result['message'] as String;
      },
    );
    secret.clear();
    secret.dispose();
    model.dispose();
  }

  Future<void> resetProvider(
      String channel, Map<String, dynamic> config) async {
    await editor(
        'Khôi phục cấu hình máy chủ',
        (_, working) => [
              const Text(
                  'Bỏ cấu hình quản trị của kênh này và dùng lại provider Gemini, model và key từ môi trường máy chủ. Kênh còn lại giữ cấu hình riêng.',
                  style: TextStyle(color: Color(0xFFCBD5E1), height: 1.5))
            ],
        () => save('providers/$channel/reset', {'revision': config['revision']},
            method: 'POST'));
  }

  Future<void> editor(
      String title,
      List<Widget> Function(void Function(VoidCallback), bool) fields,
      Future<void> Function() submit,
      {Future<String> Function()? check}) async {
    final form = GlobalKey<FormState>();
    bool working = false;
    String? error;
    String? checked;
    final route = DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Theme(
              data: _adminDarkTheme,
              child: StatefulBuilder(
                  builder: (ctx, update) => PopScope(
                      canPop: !working,
                      child: Dialog(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Color(0xFF1E293B)),
                          ),
                          insetPadding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: 620,
                                  maxHeight: MediaQuery.sizeOf(ctx).height - 32),
                              child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E1B4B),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(0xFF6366F1)
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: const Icon(
                                                  Icons.edit_note_rounded,
                                                  color: Color(0xFF818CF8),
                                                  size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(title,
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Color(0xFFF8FAFC))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        const Divider(color: Color(0xFF1E293B)),
                                        const SizedBox(height: 16),
                                        Flexible(
                                            child: SingleChildScrollView(
                                                child: Form(
                                                    key: form,
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: fields(
                                                            update, working))))),
                                        if (checked != null)
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 14),
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0x1F10B981),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: const Color(0xFF10B981)
                                                          .withValues(alpha: 0.4)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.check_circle_outline,
                                                        color: Color(0xFF10B981),
                                                        size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(checked!,
                                                          style: const TextStyle(
                                                              color: Color(
                                                                  0xFF34D399),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        if (error != null)
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 14),
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0x1FF43F5E),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: const Color(0xFFF43F5E)
                                                          .withValues(alpha: 0.4)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.error_outline,
                                                        color: Color(0xFFF43F5E),
                                                        size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(error!,
                                                          style: const TextStyle(
                                                              color: Color(
                                                                  0xFFFB7185))),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        const SizedBox(height: 24),
                                        Wrap(
                                            alignment: WrapAlignment.end,
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              TextButton(
                                                  onPressed: working
                                                      ? null
                                                      : () => Navigator.pop(ctx),
                                                  child: const Text('Hủy')),
                                              if (check != null)
                                                OutlinedButton(
                                                    onPressed: working
                                                        ? null
                                                        : () async {
                                                            if (!form
                                                                .currentState!
                                                                .validate()) {
                                                              return;
                                                            }
                                                            update(() {
                                                              working = true;
                                                              error = null;
                                                              checked = null;
                                                            });
                                                            try {
                                                              final result =
                                                                  await check();
                                                              if (ctx.mounted) {
                                                                update(() =>
                                                                    checked =
                                                                        result);
                                                              }
                                                            } catch (e) {
                                                              if (ctx.mounted) {
                                                                update(() => error =
                                                                    e is ApiFailure
                                                                        ? e.message
                                                                        : 'Chưa kiểm tra được kết nối.');
                                                              }
                                                            } finally {
                                                              if (ctx.mounted) {
                                                                update(() =>
                                                                    working =
                                                                        false);
                                                              }
                                                            }
                                                          },
                                                    child: const Text(
                                                        'Kiểm tra kết nối')),
                                              FilledButton(
                                                  onPressed: working
                                                      ? null
                                                      : () async {
                                                          if (!form.currentState!
                                                              .validate()) {
                                                            return;
                                                          }
                                                          update(() {
                                                            working = true;
                                                            error = null;
                                                          });
                                                          try {
                                                            await submit();
                                                            if (ctx.mounted) {
                                                              Navigator.pop(ctx);
                                                            }
                                                          } catch (e) {
                                                            if (ctx.mounted) {
                                                              update(() {
                                                                working = false;
                                                                error = e
                                                                        is ApiFailure
                                                                    ? e.message
                                                                    : 'Chưa lưu được. Vui lòng thử lại.';
                                                              });
                                                            }
                                                          }
                                                        },
                                                  child: Text(working
                                                      ? 'Đang lưu…'
                                                      : 'Lưu thay đổi'))
                                            ]),
                                      ]))))))));
    await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
  }

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A0':
      case 'A1':
        return const Color(0xFF3B82F6);
      case 'A2':
        return const Color(0xFF06B6D4);
      case 'B1':
        return const Color(0xFF10B981);
      case 'B2':
        return const Color(0xFFF59E0B);
      case 'C1':
      case 'C2':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildLevelBadge(String level) {
    final color = _levelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool active,
    String activeText = 'Đang hoạt động',
    String inactiveText = 'Tạm khóa',
  }) {
    final color = active ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? activeText : inactiveText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    if (!state.isAdmin) {
      return Scaffold(
          backgroundColor: const Color(0xFF090D16),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D121F),
            title: const Text('Quản trị'),
          ),
          body: const Center(
              child: Text(
            'Bạn không có quyền truy cập khu vực này.',
            style: TextStyle(color: Color(0xFFCBD5E1)),
          )));
    }
    final resource = ref.watch(adminDataProvider(key));

    final side = ListView(padding: const EdgeInsets.all(16), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogoWordmark(logoSize: 32, fontSize: 19),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 12, color: Color(0xFF818CF8)),
                  SizedBox(width: 4),
                  Text(
                    'ADMIN CONSOLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF818CF8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < sections.length; i++)
        Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: tab == i ? const Color(0x286366F1) : Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: tab == i
                      ? BorderSide(
                          color:
                              const Color(0xFF6366F1).withValues(alpha: 0.35))
                      : BorderSide.none),
              child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  selected: tab == i,
                  selectedTileColor: Colors.transparent,
                  leading: Icon(
                    sections[i].$2,
                    color: tab == i
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF94A3B8),
                  ),
                  title: Text(
                    sections[i].$1,
                    style: TextStyle(
                      color: tab == i ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight:
                          tab == i ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                  trailing: tab == i
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF818CF8),
                          ),
                        )
                      : null,
                  onTap: () {
                    select(i);
                    if (MediaQuery.sizeOf(context).width < 1100) {
                      Navigator.pop(context);
                    }
                  }),
            )),
      const SizedBox(height: 12),
      const Divider(color: Color(0xFF1E293B)),
      const SizedBox(height: 8),
      ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.logout, color: Color(0xFFF43F5E)),
          title: const Text('Đăng xuất',
              style: TextStyle(
                  color: Color(0xFFF43F5E), fontWeight: FontWeight.w600)),
          onTap: () => ref.read(authControllerProvider.notifier).signOut())
    ]);

    return Theme(
      data: _adminDarkTheme,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 1100;
        return Scaffold(
            backgroundColor: const Color(0xFF090D16),
            drawer: wide
                ? null
                : Drawer(
                    backgroundColor: const Color(0xFF0D121F),
                    child: SafeArea(child: side)),
            appBar: wide
                ? null
                : AppBar(
                    backgroundColor: const Color(0xFF0D121F),
                    title: Text(
                      'Quản trị · ${sections[tab].$1}',
                      style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.w700),
                    ),
                    actions: [
                        IconButton(
                            onPressed: busy ? null : refresh,
                            tooltip: 'Tải lại',
                            icon: const Icon(Icons.refresh,
                                color: Color(0xFF818CF8)))
                      ]),
            body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (wide)
                SizedBox(
                    width: 260,
                    child: Material(
                        color: const Color(0xFF0D121F),
                        shape: const Border(
                            right: BorderSide(
                                color: Color(0xFF1E293B), width: 1)),
                        child: SafeArea(child: side))),
              Expanded(
                  child: SafeArea(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                    Padding(
                        padding: EdgeInsets.all(wide ? 28 : 20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (wide)
                                Row(children: [
                                  Expanded(
                                      child: Text(sections[tab].$1,
                                          style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFF8FAFC),
                                              letterSpacing: -0.5))),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF131B2E),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFF1E293B)),
                                    ),
                                    child: IconButton(
                                        onPressed: busy ? null : refresh,
                                        tooltip: 'Tải lại',
                                        icon: const Icon(Icons.refresh,
                                            color: Color(0xFF818CF8),
                                            size: 20)),
                                  )
                                ]),
                              const SizedBox(height: 4),
                              const Text(
                                  'Dữ liệu hệ thống thật · chỉ dành cho quản trị viên',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13.5)),
                              const SizedBox(height: 18),
                              if (tab == 1 || tab == 2) ...[
                                TextField(
                                    controller: search,
                                    style: const TextStyle(
                                        color: Color(0xFFF8FAFC)),
                                    decoration: InputDecoration(
                                        hintText: tab == 1
                                            ? 'Tìm theo tên hoặc email'
                                            : 'Tìm tình huống',
                                        prefixIcon: const Icon(Icons.search,
                                            color: Color(0xFF818CF8)),
                                        border: const OutlineInputBorder()),
                                    onChanged: (v) {
                                      debounce?.cancel();
                                      debounce = Timer(
                                          const Duration(milliseconds: 300), () {
                                        if (mounted) {
                                          setState(() {
                                            query = v;
                                            page = 0;
                                          });
                                        }
                                      });
                                    }),
                                const SizedBox(height: 14)
                              ],
                              Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (tab == 1 || tab == 2)
                                      SizedBox(
                                          width: 210,
                                          child: DropdownButtonFormField<String>(
                                              key: ValueKey('filter-$tab'),
                                              initialValue: filter,
                                              isExpanded: true,
                                              dropdownColor:
                                                  const Color(0xFF0F172A),
                                              decoration: const InputDecoration(
                                                  labelText: 'Bộ lọc',
                                                  border: OutlineInputBorder()),
                                              items: (tab == 1
                                                      ? ['', ...levels]
                                                      : ['', 'active', 'hidden'])
                                                  .map((v) => DropdownMenuItem(
                                                      value: v,
                                                      child: Text(v.isEmpty
                                                          ? 'Tất cả'
                                                          : v == 'active'
                                                              ? 'Đang xuất bản'
                                                              : v == 'hidden'
                                                                  ? 'Đang ẩn'
                                                                  : v)))
                                                  .toList(),
                                              onChanged: (v) => setState(() {
                                                    filter = v ?? '';
                                                    page = 0;
                                                  }))),
                                    if (tab == 2)
                                      FilledButton.icon(
                                          onPressed: busy
                                              ? null
                                              : () => editScenario(),
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Thêm tình huống')),
                                    if (tab == 3)
                                      FilledButton.icon(
                                          onPressed: busy
                                              ? null
                                              : () => editTopic(),
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Thêm chủ đề')),
                                  ]),
                            ])),
                    Expanded(
                        child: resource.when(
                            loading: () => const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF6366F1))),
                            error: (e, _) => Center(
                                child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.error_outline,
                                              size: 48,
                                              color: Color(0xFFF43F5E)),
                                          const SizedBox(height: 16),
                                          Text(
                                              e is ApiFailure
                                                  ? e.message
                                                  : 'Không tải được dữ liệu.',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Color(0xFFCBD5E1),
                                                  fontSize: 15)),
                                          const SizedBox(height: 16),
                                          OutlinedButton(
                                              onPressed: refresh,
                                              child: const Text('Thử lại'))
                                        ]))),
                            data: (data) => content(data))),
                  ])))
            ]));
      }),
    );
  }

  Widget content(Object? data) {
    if (tab == 6) {
      return UsageDashboard(
          data: data as Map<String, dynamic>,
          days: usageDays,
          provider: filter,
          onDays: (v) => setState(() => usageDays = v),
          onProvider: (v) => setState(() => filter = v));
    }
    if (tab == 0) {
      final d = data as Map<String, dynamic>;
      final kpis = [
        (
          'Hồ sơ học viên',
          d['learners'],
          Icons.people_alt_rounded,
          const [Color(0xFF6366F1), Color(0xFF4F46E5)],
          const Color(0xFF818CF8)
        ),
        (
          'Học viên tạm khóa',
          d['suspendedLearners'],
          Icons.block_rounded,
          const [Color(0xFFF43F5E), Color(0xFFBE123C)],
          const Color(0xFFFB7185)
        ),
        (
          'Tình huống xuất bản',
          d['activeScenarios'],
          Icons.auto_stories_rounded,
          const [Color(0xFF10B981), Color(0xFF059669)],
          const Color(0xFF34D399)
        ),
        (
          'Chủ đề',
          d['topics'],
          Icons.category_rounded,
          const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          const Color(0xFFA78BFA)
        ),
        (
          'Phiên hoàn thành',
          d['completedSessions'],
          Icons.task_alt_rounded,
          const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          const Color(0xFF38BDF8)
        ),
        (
          'Phút từ phiên hoàn thành',
          d['completedMinutes'],
          Icons.timer_rounded,
          const [Color(0xFFF59E0B), Color(0xFFD97706)],
          const Color(0xFFFBBF24)
        ),
      ];

      return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            AcademicGrid(minWidth: 240, children: [
              for (final item in kpis)
                AcademicPanel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: item.$4,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: item.$5.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(item.$3, color: Colors.white, size: 20),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trending_up,
                                    size: 12, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text('LIVE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('${item.$2}',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF8FAFC),
                              letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text(item.$1,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500))
                    ]))
            ]),
            const AcademicHeading(
                'Hoạt động 7 ngày', 'Số phiên được tạo mỗi ngày, theo UTC.'),
            AcademicPanel(
                child: Column(children: [
              for (final day in (d['weekly'] as List).whereType<Map>()) ...[
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(
                          child: Text('${day['date']}',
                              style: const TextStyle(
                                  color: Color(0xFFF8FAFC),
                                  fontWeight: FontWeight.w600))),
                      Text('${day['sessions']} phiên',
                          style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.w700))
                    ])),
                if (day != (d['weekly'] as List).last)
                  const Divider(color: Color(0xFF1E293B), height: 1),
              ]
            ])),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D121F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF818CF8)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thống kê hồ sơ trong app; không tính tài khoản Auth chưa tạo hồ sơ. Phút Live chưa được cộng vào số phút hoàn thành.',
                      style: TextStyle(
                          color: Color(0xFF94A3B8), height: 1.5, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            )
          ]);
    }
    if (tab == 5) {
      final d = data as Map;
      return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            AcademicPanel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B4B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.psychology_rounded,
                            color: Color(0xFF818CF8), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tom & kết nối',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF8FAFC))),
                            SizedBox(height: 4),
                            Text('Cấu hình dịch vụ AI chat và đàm thoại Live',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Chat Service Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D121F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                size: 18, color: Color(0xFF818CF8)),
                            Text(
                              'Chat: ${d['textConfigured'] == true ? 'Đã cấu hình' : 'Chưa cấu hình'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF8FAFC)),
                            ),
                            _buildStatusBadge(
                              active: d['textConfigured'] == true,
                              activeText: 'Sẵn sàng',
                              inactiveText: 'Chưa cấu hình',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Model chat: ',
                                style: TextStyle(color: Color(0xFF94A3B8))),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${d['textModel']}',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Color(0xFF38BDF8),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Live Service Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D121F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.mic_none_outlined,
                                size: 18, color: Color(0xFF38BDF8)),
                            Text(
                              'Live: ${d['liveConfigured'] == true ? 'Đã cấu hình' : 'Chưa cấu hình'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF8FAFC)),
                            ),
                            _buildStatusBadge(
                              active: d['liveConfigured'] == true,
                              activeText: 'Sẵn sàng',
                              inactiveText: 'Chưa cấu hình',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Model Live: ',
                                style: TextStyle(color: Color(0xFF94A3B8))),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${d['liveModel']}',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Color(0xFF38BDF8),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  for (final channel in ['text', 'live'])
                    if (d['${channel}Config'] is Map) ...[
                      const SizedBox(height: 24),
                      Text(
                          channel == 'text'
                              ? 'Provider chat'
                              : 'Provider giọng nói',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFFF8FAFC))),
                      const SizedBox(height: 8),
                      Text(
                          'Provider: ${d['${channel}Config']['provider']} · Nguồn: ${d['${channel}Config']['source'] == 'database' ? 'Quản trị' : 'Máy chủ'}',
                          style: const TextStyle(color: Color(0xFF94A3B8))),
                      const SizedBox(height: 14),
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        FilledButton.icon(
                            onPressed: busy ||
                                    d['${channel}Config']['editable'] != true
                                ? null
                                : () => editProvider(
                                    channel,
                                    Map<String, dynamic>.from(
                                        d['${channel}Config'] as Map)),
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('Thay đổi cấu hình')),
                        if (d['${channel}Config']['source'] == 'database')
                          OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => resetProvider(
                                      channel,
                                      Map<String, dynamic>.from(
                                          d['${channel}Config'] as Map)),
                              child: const Text('Khôi phục cấu hình máy chủ')),
                      ]),
                      if (d['${channel}Config']['editable'] != true)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                              'Cần cấu hình khóa mã hóa trên máy chủ để lưu key an toàn.',
                              style: TextStyle(color: Color(0xFFF59E0B))),
                        ),
                    ],
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFF1E293B)),
                  const SizedBox(height: 20),
                  AcademicGrid(minWidth: 160, children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D121F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hạn mức gọi',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 12)),
                          const SizedBox(height: 6),
                          Text('${d['dailyVoiceMinutes']} phút/ngày',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF8FAFC))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D121F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hạn mức chat',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 12)),
                          const SizedBox(height: 6),
                          Text('${d['maxDailyTextTurns']} lượt/ngày',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF8FAFC))),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x1F6366F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xFF818CF8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${d['telemetry']}',
                                  style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      height: 1.5,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Đây là trạng thái cấu hình, không phải phép thử upstream. Key được mã hóa trên máy chủ và không hiển thị lại. Chỉ admin được thay cấu hình.',
                            style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                height: 1.5)),
                      ],
                    ),
                  )
                ]))
          ]);
    }
    final list = tab == 3
        ? (data as List).whereType<Map<String, dynamic>>().toList()
        : ((data as Map)['items'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
    return Column(children: [
      Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('Chưa có dữ liệu phù hợp.',
                      style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return AcademicPanel(
                        padding: 20,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tab == 1) ...[
                                Text(
                                  '${item['displayName']}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF8FAFC),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('${item['email'] ?? ''}',
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    _buildLevelBadge(
                                        item['level'] as String? ?? 'A1'),
                                    _buildStatusBadge(
                                      active: item['suspended'] != true,
                                      activeText: 'Đang hoạt động',
                                      inactiveText: 'Tạm khóa',
                                    ),
                                    Text(
                                      '${item['level']} · ${item['dailyMinutes']} phút/ngày · ${item['suspended'] == true ? 'Tạm khóa' : 'Đang hoạt động'}',
                                      style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => editLearner(item),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    label: const Text('Quản lý học viên'))
                              ],
                              if (tab == 2) ...[
                                Text('${item['title']}',
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFF8FAFC))),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildLevelBadge(item['level']
                                            as String? ??
                                        'A1'),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            const Color(0xFF1E293B),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons.timer_outlined,
                                              size: 13,
                                              color:
                                                  Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item['estimatedMinutes']} phút',
                                            style: const TextStyle(
                                                color:
                                                    Color(0xFFCBD5E1),
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildStatusBadge(
                                      active: item['active'] == true,
                                      activeText: 'Đã xuất bản',
                                      inactiveText: 'Đang ẩn',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                    '${item['level']} · ${item['estimatedMinutes']} phút · ${item['active'] == true ? 'Đã xuất bản' : 'Đang ẩn'}',
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12)),
                                const SizedBox(height: 8),
                                Text('${item['description']}',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        height: 1.6,
                                        fontSize: 13.5)),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => editScenario(item),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    label: const Text('Chỉnh sửa'))
                              ],
                              if (tab == 3) ...[
                                Text('${item['title']}',
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFF8FAFC))),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D121F),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    border: Border.all(
                                        color:
                                            const Color(0xFF334155)),
                                  ),
                                  child: Text(
                                    '${item['slug']}',
                                    style: const TextStyle(
                                        fontFamily: 'monospace',
                                        color: Color(0xFF818CF8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                    onPressed:
                                        busy ? null : () => editTopic(item),
                                    child: const Text('Chỉnh sửa'))
                              ],
                              if (tab == 4) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1B4B),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFF6366F1)
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        '${item['action']}',
                                        style: const TextStyle(
                                            color: Color(0xFF818CF8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text('${item['createdAt']}',
                                        style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SelectableText('Đối tượng: ${item['target']}',
                                    style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 13.5)),
                                const SizedBox(height: 6),
                                SelectableText(
                                    'Người thực hiện: ${item['actorId']}',
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12.5)),
                              ],
                            ]));
                  })),
      if (tab != 3)
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D121F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                            'Trang ${page + 1} · ${(data as Map)['total']} kết quả',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        TextButton(
                            onPressed:
                                page > 0 ? () => setState(() => page--) : null,
                            child: const Text('Trước')),
                        TextButton(
                            onPressed: data['hasMore'] == true
                                ? () => setState(() => page++)
                                : null,
                            child: const Text('Sau'))
                      ]),
                )))
    ]);
  }
}
