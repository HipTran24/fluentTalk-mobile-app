import 'usage_dashboard.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/theme/app_colors.dart';
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
                  style: const TextStyle(color: AppColors.textMuted)),
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
                  decoration:
                      const InputDecoration(labelText: 'Trình độ tự chọn'),
                  items: levels
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged:
                      working ? null : (v) => update(() => level = v ?? level)),
              const SizedBox(height: 16),
              Text('Mục tiêu: $minutes phút/ngày'),
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
                  title: const Text('Tạm khóa quyền sử dụng app'),
                  subtitle: const Text(
                      'Không xóa tài khoản hoặc dữ liệu. Tài khoản bị khóa vẫn có thể xác thực email nhưng sẽ bị chặn API. Cuộc gọi Live đã mở có thể tiếp tục đến khi token hết hạn (tối đa 5 phút).'),
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
                  decoration: const InputDecoration(labelText: 'Trình độ'),
                  items: levels
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged:
                      working ? null : (v) => update(() => level = v ?? level)),
              const SizedBox(height: 18),
              Text('Thời lượng dự kiến: $minutes phút'),
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
                  title: const Text('Xuất bản trong danh mục'),
                  subtitle: const Text(
                      'Tắt để ẩn khỏi danh mục học viên; lịch sử cũ được giữ nguyên.'),
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
            'Áp dụng cho yêu cầu mới ngay sau khi lưu. Cuộc gọi đang mở giữ cấu hình cũ đến khi kết thúc.'),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: provider,
          isExpanded: true,
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
        Text(channel == 'text'
            ? 'Chọn model chat hỗ trợ JSON. Nút kiểm tra gửi một câu chào thử, có thể tính phí theo provider.'
            : 'Live hiện hỗ trợ Gemini. Kiểm tra chỉ cấp phiên ngắn hạn, chưa kiểm tra âm thanh trình duyệt.'),
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
                  'Bỏ cấu hình quản trị của kênh này và dùng lại provider Gemini, model và key từ môi trường máy chủ. Kênh còn lại giữ cấu hình riêng.')
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
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => PopScope(
                canPop: !working,
                child: Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: 620,
                            maxHeight: MediaQuery.sizeOf(ctx).height - 32),
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(title,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 20),
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
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(checked!)),
                                  if (error != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(error!,
                                            style: const TextStyle(
                                                color: AppColors.error))),
                                  const SizedBox(height: 20),
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
                                                      if (!form.currentState!
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
                                                              checked = result);
                                                        }
                                                      } catch (e) {
                                                        if (ctx.mounted) {
                                                          update(() => error = e
                                                                  is ApiFailure
                                                              ? e.message
                                                              : 'Chưa kiểm tra được kết nối.');
                                                        }
                                                      } finally {
                                                        if (ctx.mounted) {
                                                          update(() =>
                                                              working = false);
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
                                ])))))));
    await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    if (!state.isAdmin) {
      return Scaffold(
          appBar: AppBar(title: const Text('Quản trị')),
          body: const Center(
              child: Text('Bạn không có quyền truy cập khu vực này.')));
    }
    final resource = ref.watch(adminDataProvider(key));
    final side = ListView(padding: const EdgeInsets.all(16), children: [
      const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: AppLogoWordmark(logoSize: 32, fontSize: 19)),
      const SizedBox(height: 16),
      for (var i = 0; i < sections.length; i++)
        Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                selected: tab == i,
                selectedTileColor: AppColors.secondaryLight,
                leading: Icon(sections[i].$2),
                title: Text(sections[i].$1),
                onTap: () {
                  select(i);
                  if (MediaQuery.sizeOf(context).width < 1100) {
                    Navigator.pop(context);
                  }
                })),
      const Divider(),
      ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Đăng xuất'),
          onTap: () => ref.read(authControllerProvider.notifier).signOut())
    ]);
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1100;
      return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          drawer: wide ? null : Drawer(child: SafeArea(child: side)),
          appBar: wide
              ? null
              : AppBar(title: Text('Quản trị · ${sections[tab].$1}'), actions: [
                  IconButton(
                      onPressed: busy ? null : refresh,
                      tooltip: 'Tải lại',
                      icon: const Icon(Icons.refresh))
                ]),
          body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (wide)
              SizedBox(
                  width: 240,
                  child: Material(
                      color: Colors.white, child: SafeArea(child: side))),
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
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800))),
                                IconButton(
                                    onPressed: busy ? null : refresh,
                                    tooltip: 'Tải lại',
                                    icon: const Icon(Icons.refresh))
                              ]),
                            const Text(
                                'Dữ liệu hệ thống thật · chỉ dành cho quản trị viên',
                                style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(height: 16),
                            if (tab == 1 || tab == 2) ...[
                              TextField(
                                  controller: search,
                                  decoration: InputDecoration(
                                      hintText: tab == 1
                                          ? 'Tìm theo tên hoặc email'
                                          : 'Tìm tình huống',
                                      prefixIcon: const Icon(Icons.search),
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
                              const SizedBox(height: 12)
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
                                        onPressed:
                                            busy ? null : () => editScenario(),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Thêm tình huống')),
                                  if (tab == 3)
                                    FilledButton.icon(
                                        onPressed:
                                            busy ? null : () => editTopic(),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Thêm chủ đề')),
                                ]),
                          ])),
                  Expanded(
                      child: resource.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(
                              child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            e is ApiFailure
                                                ? e.message
                                                : 'Không tải được dữ liệu.',
                                            textAlign: TextAlign.center),
                                        TextButton(
                                            onPressed: refresh,
                                            child: const Text('Thử lại'))
                                      ]))),
                          data: (data) => content(data))),
                ])))
          ]));
    });
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
      return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            AcademicGrid(minWidth: 240, children: [
              for (final item in [
                ('Hồ sơ học viên', d['learners']),
                ('Học viên tạm khóa', d['suspendedLearners']),
                ('Tình huống xuất bản', d['activeScenarios']),
                ('Chủ đề', d['topics']),
                ('Phiên hoàn thành', d['completedSessions']),
                ('Phút từ phiên hoàn thành', d['completedMinutes'])
              ])
                AcademicPanel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${item.$2}',
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(item.$1,
                          style: const TextStyle(color: AppColors.textMuted))
                    ]))
            ]),
            const AcademicHeading(
                'Hoạt động 7 ngày', 'Số phiên được tạo mỗi ngày, theo UTC.'),
            AcademicPanel(
                child: Column(children: [
              for (final day in (d['weekly'] as List).whereType<Map>())
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(child: Text('${day['date']}')),
                      Text('${day['sessions']} phiên',
                          style: const TextStyle(fontWeight: FontWeight.w700))
                    ]))
            ])),
            const SizedBox(height: 16),
            const Text(
                'Thống kê hồ sơ trong app; không tính tài khoản Auth chưa tạo hồ sơ. Phút Live chưa được cộng vào số phút hoàn thành.',
                style: TextStyle(color: AppColors.textMuted, height: 1.6))
          ]);
    }
    if (tab == 5) {
      final d = data as Map;
      return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            AcademicPanel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Tom & kết nối',
                      style:
                          TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  Text(
                      'Chat: ${d['textConfigured'] == true ? 'Đã cấu hình' : 'Chưa cấu hình'}'),
                  Text('Model chat: ${d['textModel']}'),
                  const SizedBox(height: 12),
                  Text(
                      'Live: ${d['liveConfigured'] == true ? 'Đã cấu hình' : 'Chưa cấu hình'}'),
                  Text('Model Live: ${d['liveModel']}'),
                  for (final channel in ['text', 'live'])
                    if (d['${channel}Config'] is Map) ...[
                      const SizedBox(height: 24),
                      Text(
                          channel == 'text'
                              ? 'Provider chat'
                              : 'Provider giọng nói',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                          'Provider: ${d['${channel}Config']['provider']} · Nguồn: ${d['${channel}Config']['source'] == 'database' ? 'Quản trị' : 'Máy chủ'}'),
                      const SizedBox(height: 12),
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        FilledButton.icon(
                            onPressed: busy ||
                                    d['${channel}Config']['editable'] != true
                                ? null
                                : () => editProvider(
                                    channel,
                                    Map<String, dynamic>.from(
                                        d['${channel}Config'] as Map)),
                            icon: const Icon(Icons.tune),
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
                        const Text(
                            'Cần cấu hình khóa mã hóa trên máy chủ để lưu key an toàn.'),
                    ],
                  const SizedBox(height: 20),
                  Text('Hạn mức gọi: ${d['dailyVoiceMinutes']} phút/ngày'),
                  Text('Hạn mức chat: ${d['maxDailyTextTurns']} lượt/ngày'),
                  const SizedBox(height: 20),
                  Text('${d['telemetry']}',
                      style: const TextStyle(
                          color: AppColors.textMuted, height: 1.6)),
                  const SizedBox(height: 12),
                  const Text(
                      'Đây là trạng thái cấu hình, không phải phép thử upstream. Key được mã hóa trên máy chủ và không hiển thị lại. Chỉ admin được thay cấu hình.',
                      style: TextStyle(height: 1.6))
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
              ? const Center(child: Text('Chưa có dữ liệu phù hợp.'))
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
                              Text(
                                  tab == 1
                                      ? '${item['displayName']}'
                                      : tab == 4
                                          ? '${item['action']}'
                                          : '${item['title']}',
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              if (tab == 1) ...[
                                Text('${item['email'] ?? ''}',
                                    style: const TextStyle(
                                        color: AppColors.textMuted)),
                                const SizedBox(height: 8),
                                Text(
                                    '${item['level']} · ${item['dailyMinutes']} phút/ngày · ${item['suspended'] == true ? 'Tạm khóa' : 'Đang hoạt động'}'),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                    onPressed:
                                        busy ? null : () => editLearner(item),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Quản lý học viên'))
                              ],
                              if (tab == 2) ...[
                                Text(
                                    '${item['level']} · ${item['estimatedMinutes']} phút · ${item['active'] == true ? 'Đã xuất bản' : 'Đang ẩn'}'),
                                const SizedBox(height: 12),
                                Text('${item['description']}',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        height: 1.6)),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                    onPressed:
                                        busy ? null : () => editScenario(item),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Chỉnh sửa'))
                              ],
                              if (tab == 3) ...[
                                Text('${item['slug']}'),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                    onPressed:
                                        busy ? null : () => editTopic(item),
                                    child: const Text('Chỉnh sửa'))
                              ],
                              if (tab == 4) ...[
                                SelectableText('Đối tượng: ${item['target']}'),
                                const SizedBox(height: 6),
                                SelectableText(
                                    'Người thực hiện: ${item['actorId']}'),
                                const SizedBox(height: 6),
                                Text('${item['createdAt']}',
                                    style: const TextStyle(
                                        color: AppColors.textMuted))
                              ],
                            ]));
                  })),
      if (tab != 3)
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                          'Trang ${page + 1} · ${(data as Map)['total']} kết quả'),
                      TextButton(
                          onPressed:
                              page > 0 ? () => setState(() => page--) : null,
                          child: const Text('Trước')),
                      TextButton(
                          onPressed: data['hasMore'] == true
                              ? () => setState(() => page++)
                              : null,
                          child: const Text('Sau'))
                    ])))
    ]);
  }
}
