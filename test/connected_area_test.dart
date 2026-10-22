import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:english_mobile_app/features/connected/presentation/connected_area_screen.dart';
import 'api_client_test.dart' show ScriptedAdapter, jsonResponse;

const profile = <String, Object?>{
  'id': '10000000-0000-0000-0000-000000000001',
  'email': 'learner@example.test',
  'displayName': 'Người học thật',
  'level': 'A1',
  'dailyMinutes': 15,
  'onboarded': false,
  'createdAt': '2026-10-22T00:00:00Z',
};

void main() {
  for (final section in [
    'home',
    'practice',
    'progress',
    'coach',
    'profile',
    'history'
  ]) {
    testWidgets('connected $section handles real empty data at 320dp / 200%',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter =
          ScriptedAdapter((request, _) => jsonResponse(request.path == 'me'
              ? profile
              : request.path == 'sessions'
                  ? {'items': []}
                  : {
                      'totalSessions': 0,
                      'totalMinutes': 0,
                      'currentStreakDays': 0,
                      'averageBand': null
                    }));
      final api = ApiClient(
          config: const AppConfig(apiBaseUrl: 'https://api.test/api/v1'),
          accessToken: () => 'fixture',
          dio: Dio()..httpClientAdapter = adapter);
      addTearDown(api.close);
      await tester.pumpWidget(ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!),
              home: ConnectedAreaScreen(section: section))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('6.0'), findsNothing);
      expect(
          adapter.requests.single.path,
          section == 'profile'
              ? 'me'
              : section == 'history'
                  ? 'sessions'
                  : 'progress/summary');
      if (['home', 'progress', 'coach'].contains(section)) {
        expect(find.text('Luyện chat với Tom'), findsNothing);
        expect(find.text('Khám phá tình huống'), findsNothing);
      }
      if (section == 'practice') {
        expect(find.text('Luyện chat với Tom'), findsOneWidget);
        expect(find.text('Lịch sử hội thoại'), findsNothing);
      }
      if (section == 'progress') {
        expect(find.text('Lịch sử hội thoại'), findsOneWidget);
      }
      if (section == 'profile') {
        expect(find.text('learner@example.test'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('failed profile save preserves edits and never announces success',
      (tester) async {
    final adapter = ScriptedAdapter((request, _) => request.method == 'PATCH'
        ? jsonResponse({
            'error': {
              'code': 'SERVICE_UNAVAILABLE',
              'message': 'Tạm thời không lưu được'
            }
          }, 503)
        : jsonResponse(profile));
    final api = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test/api/v1'),
        accessToken: () => 'fixture',
        dio: Dio()..httpClientAdapter = adapter);
    addTearDown(api.close);
    await tester.pumpWidget(ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child:
            const MaterialApp(home: ConnectedAreaScreen(section: 'profile'))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tên đã chỉnh sửa');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu hồ sơ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Tên đã chỉnh sửa'), findsOneWidget);
    expect(find.text('Đã lưu hồ sơ lên máy chủ.'), findsNothing);
    expect(
        adapter.requests.where((request) => request.method == 'PATCH').length,
        1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
