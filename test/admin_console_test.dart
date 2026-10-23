import 'dart:io';
import 'package:english_mobile_app/app/router/app_router.dart';
import 'package:english_mobile_app/main.dart';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/core/theme/app_theme.dart';
import 'package:english_mobile_app/features/admin/presentation/admin_console_screen.dart';
import 'package:english_mobile_app/features/auth/domain/auth_state.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'api_client_test.dart' show ScriptedAdapter, jsonResponse;
import 'auth_route_guard_test.dart' show ControlledAuth;

void main() {
  setUpAll(() async {
    await (FontLoader('PlusJakartaSans')
          ..addFont(
              rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  final summary = {
    'learners': 23,
    'suspendedLearners': 0,
    'activeScenarios': 12,
    'topics': 4,
    'completedSessions': 38,
    'completedMinutes': 124,
    'weekly': [
      for (var i = 17; i <= 23; i++) {'date': '2026-10-$i', 'sessions': i - 17}
    ]
  };
  final learner = {
    'id': 'fixture',
    'displayName': 'Học viên thử nghiệm',
    'email': 'learner@example.test',
    'level': 'A1',
    'dailyMinutes': 15,
    'suspended': false,
    'revision': 0
  };
  final topic = {
    'id': '10000000-0000-0000-0000-000000000001',
    'title': 'Giao tiếp',
    'slug': 'conversation'
  };
  ResponseBody respond(RequestOptions req, int _) {
    if (req.path.endsWith('/check')) {
      return jsonResponse({'ok': true, 'message': 'Kết nối thử thành công.'});
    }
    if (req.method != 'GET') {
      return jsonResponse({
        'code': 'CONFLICT',
        'message': 'Dữ liệu đã thay đổi. Tải lại trước khi lưu.'
      }, 409);
    }
    if (req.path.endsWith('usage')) {
      final empty = {
        'requests': 0,
        'errors': 0,
        'unknownUsage': 0,
        'checks': 0,
        'inputTokens': 0,
        'outputTokens': 0,
        'totalTokens': 0,
        'cachedTokens': 0,
        'reasoningTokens': 0
      };
      return jsonResponse({
        'timezone': 'Asia/Ho_Chi_Minh',
        'from': '2026-10-17',
        'to': '2026-10-23',
        'totals': {
          ...empty,
          'totalTokens': 1234,
          'inputTokens': 1000,
          'outputTokens': 234,
          'requests': 3
        },
        'daily': [
          for (var day = 17; day <= 23; day++)
            {
              ...empty,
              'date': '2026-10-$day',
              'totalTokens': day == 23 ? 1234 : 0,
              'requests': day == 23 ? 3 : 0
            }
        ],
        'models': [
          {
            'provider': 'gemini',
            'model': 'fixture-model',
            ...empty,
            'requests': 3,
            'totalTokens': 1234
          }
        ],
        'coverage': 'Token chat từ metadata provider; Live chưa đo token.'
      });
    }
    if (req.path.endsWith('summary')) return jsonResponse(summary);
    if (req.path.endsWith('topics')) return jsonResponse([topic]);
    if (req.path.endsWith('services')) {
      return jsonResponse({
        for (final channel in ['text', 'live'])
          '${channel}Config': {
            'provider': 'gemini',
            'model': 'configured-model',
            'revision': -1,
            'keyConfigured': true,
            'source': 'environment',
            'editable': true
          },
        'textConfigured': true,
        'liveConfigured': true,
        'textModel': 'configured-text',
        'liveModel': 'configured-live',
        'dailyVoiceMinutes': 15,
        'maxDailyTextTurns': 100,
        'telemetry': 'Chưa tích hợp đo chi phí.'
      });
    }
    return jsonResponse({
      'items': req.path.endsWith('learners') ? [learner] : [],
      'total': 1,
      'hasMore': false,
      'page': 0,
      'size': 20
    });
  }

  Future<
      ({
        ProviderContainer container,
        ApiClient api,
        ScriptedAdapter adapter
      })> mount(WidgetTester tester, {bool admin = true}) async {
    final adapter = ScriptedAdapter(respond);
    final api = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test/api/v1'),
        accessToken: () => 'fixture',
        dio: Dio()..httpClientAdapter = adapter);
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => ControlledAuth(
          AuthState(status: AuthStatus.authenticated, isAdmin: admin))),
      apiClientProvider.overrideWithValue(api)
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RepaintBoundary(
                key: ValueKey('capture'), child: AdminConsoleScreen()))));
    await tester.pumpAndSettle();
    addTearDown(() {
      container.dispose();
      api.close();
    });
    return (container: container, api: api, adapter: adapter);
  }

  Future<void> select(WidgetTester tester, String title, bool wide) async {
    if (!wide) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(ListTile, title));
    await tester.pumpAndSettle();
  }

  for (final size in [
    (1440.0, 1000.0, 1.0),
    (886.0, 900.0, 1.0),
    (390.0, 844.0, 1.0),
    (320.0, 740.0, 2.0)
  ]) {
    testWidgets('admin sections fit ${size.$1} text scale ${size.$3}',
        (tester) async {
      tester.view.physicalSize = Size(size.$1, size.$2);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = size.$3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await mount(tester);
      expect(tester.takeException(), isNull);
      if ((size.$1 == 1440 || size.$1 == 390) &&
          const bool.fromEnvironment('CAPTURE_UI')) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('capture')))
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('docs/qa/ui/admin-${size.$1.toInt()}-fixture.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      for (final title in [
        'Học viên',
        'Tình huống',
        'Chủ đề',
        'Nhật ký',
        'Dịch vụ',
        'Sử dụng'
      ]) {
        await select(tester, title, size.$1 >= 1100);
        expect(tester.takeException(), isNull, reason: title);
        if (title == 'Sử dụng' &&
            size.$1 == 1440 &&
            const bool.fromEnvironment('CAPTURE_UI')) {
          await tester.runAsync(() async {
            final image = await tester
                .renderObject<RenderRepaintBoundary>(
                    find.byKey(const ValueKey('capture')))
                .toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await File('docs/qa/ui/admin-usage-fixture.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        if (title == 'Dịch vụ') {
          await tester.ensureVisible(find.text('Thay đổi cấu hình').first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Thay đổi cấu hình').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Hủy'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        if (title == 'Học viên') {
          await tester.ensureVisible(find.text('Quản lý học viên'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Quản lý học viên'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Hủy'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('real admin route renders at full desktop width', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await mount(tester);
    final router = app.container.read(appRouterProvider);
    router.go('/admin');
    await tester.pumpWidget(UncontrolledProviderScope(
        container: app.container, child: const FluentTalkApp()));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/admin');
    expect(tester.getSize(find.byType(AdminConsoleScreen)).width, 1440);
    expect(tester.takeException(), isNull);
    for (final path in [
      '/home',
      '/profile',
      '/practice',
      '/practice/text',
      '/practice/voice',
      '/progress',
      '/coach',
      '/practice/scenarios',
      '/auth'
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/admin',
          reason: path);
    }
    expect(find.text('Về trang học'), findsNothing);
    expect(find.text('Đăng xuất'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('provider form masks key and probe never saves config',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await mount(tester);
    await select(tester, 'Dịch vụ', true);
    await tester.ensureVisible(find.text('Thay đổi cấu hình').first);
    await tester.tap(find.text('Thay đổi cấu hình').first);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'new-model');
    await tester.enterText(fields.at(1), 'private-fixture-key');
    expect(
        tester
            .widget<EditableText>(find.descendant(
                of: fields.at(1), matching: find.byType(EditableText)))
            .obscureText,
        isTrue);
    await tester.tap(find.text('Kiểm tra kết nối'));
    await tester.pumpAndSettle();
    expect(find.text('Kết nối thử thành công.'), findsOneWidget);
    expect(app.adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
    expect(app.adapter.requests.last.data['apiKey'], 'private-fixture-key');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(app.adapter.requests.last.method, 'PUT');
    expect(app.adapter.requests.last.data['revision'], -1);
    expect(find.text('Đã lưu thay đổi.'), findsNothing);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('usage chart filters provider and range, shows day details',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await mount(tester);
    await select(tester, 'Sử dụng', true);
    expect(find.text('Token đã xác nhận'), findsOneWidget);
    expect(app.adapter.requests.last.queryParameters['days'], 7);
    await tester.tap(find.text('7 ngày gần nhất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 ngày gần nhất').last);
    await tester.pumpAndSettle();
    expect(app.adapter.requests.last.queryParameters['days'], 30);
    await tester.tap(find.text('Tất cả provider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('groq').last);
    await tester.pumpAndSettle();
    expect(app.adapter.requests.last.queryParameters['provider'], 'groq');
    await tester.ensureVisible(find.text('23/10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('23/10'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026-10-23 ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('ordinary account never requests admin data', (tester) async {
    final app = await mount(tester, admin: false);
    expect(app.adapter.requests, isEmpty);
    expect(
        find.text('Bạn không có quyền truy cập khu vực này.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('search is debounced and failed save retains learner edits',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await mount(tester);
    await select(tester, 'Học viên', true);
    await tester.enterText(find.byType(TextField).first, 'Minh');
    await tester.pump(const Duration(milliseconds: 100));
    expect(app.adapter.requests.where((r) => r.queryParameters['q'] == 'Minh'),
        isEmpty);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(app.adapter.requests.last.queryParameters['q'], 'Minh');
    await tester.tap(find.text('Quản lý học viên'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'Tên đã chỉnh sửa');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Tên đã chỉnh sửa'), findsOneWidget);
    expect(find.text('Đã lưu thay đổi.'), findsNothing);
    expect(app.adapter.requests.last.method, 'PATCH');
    expect(app.adapter.requests.last.data['revision'], 0);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
}
