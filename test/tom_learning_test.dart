import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:english_mobile_app/features/coach/presentation/tom_learning_screen.dart';
import 'api_client_test.dart' show ScriptedAdapter, jsonResponse;

Map<String, dynamic> dashboard(bool enabled) => {
      'settings': {
        'enabled': enabled,
        'saveVoiceTranscripts': false,
        'goal': 'Phỏng vấn tiếng Anh',
        'topicId': null,
        'voice': 'Aoede'
      },
      'todayMinutes': 0,
      'dailyMinutes': 15,
      'textSamples': 0,
      'voiceSamples': 0,
      'basis': 'Chưa đủ lịch sử hội thoại; đề xuất dựa trên lựa chọn của bạn.',
      'plan': [
        {'title': 'Thực hành phỏng vấn', 'minutes': 15}
      ],
      'recommendations': enabled
          ? [
              {
                'id': '10000000-0000-0000-0000-000000000001',
                'title': 'A real catalog scenario',
                'level': 'A1',
                'minutes': 10,
                'reasons': ['Phù hợp trình độ tự chọn A1']
              }
            ]
          : [],
      'evidence': [],
    };
void main() {
  testWidgets(
      'personalization is off until explicitly saved and no fake evidence appears',
      (tester) async {
    var enabled = false;
    Map<String, dynamic>? saved;
    final adapter = ScriptedAdapter((req, _) {
      if (req.path == 'topics') return jsonResponse([]);
      if (req.method == 'PATCH') {
        saved = Map<String, dynamic>.from(req.data as Map);
        enabled = saved!['enabled'] == true;
        return jsonResponse(saved!);
      }
      return jsonResponse(dashboard(enabled));
    });
    final api = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test/api/v1'),
        accessToken: () => 'fixture',
        dio: Dio()..httpClientAdapter = adapter);
    addTearDown(api.close);
    await tester.pumpWidget(ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: const MaterialApp(home: TomLearningScreen())));
    await tester.pumpAndSettle();
    expect(find.text('A real catalog scenario'), findsNothing);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.ensureVisible(find.text('Lưu cá nhân hóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu cá nhân hóa'));
    await tester.pumpAndSettle();
    expect(saved?['enabled'], true);
    expect(saved?['saveVoiceTranscripts'], false);
    expect(saved?.containsKey('userId'), false);
    expect(find.text('A real catalog scenario'), findsOneWidget);
    expect(find.textContaining('0 mẫu tin nhắn'), findsOneWidget);
    expect(find.textContaining('Chưa đủ lịch sử'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Tom dashboard stays readable at 320dp and 200 percent',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = ScriptedAdapter(
        (req, _) => jsonResponse(req.path == 'topics' ? [] : dashboard(true)));
    final api = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test/api/v1'),
        accessToken: () => 'fixture',
        dio: Dio()..httpClientAdapter = adapter);
    addTearDown(api.close);
    await tester.pumpWidget(ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: MaterialApp(
            builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const TomLearningScreen())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('A real catalog scenario'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
