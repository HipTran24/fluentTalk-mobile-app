import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/app/router/app_router.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/models/user_profile.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/main.dart';
import 'package:english_mobile_app/features/connected/presentation/connected_area_screen.dart';
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
  for (final variant in [
    (1440.0, 1000.0, 1.0),
    (390.0, 844.0, 1.0),
    (886.0, 900.0, 1.0),
    (1280.0, 640.0, 2.0)
  ]) {
    testWidgets('academic dashboard ${variant.$1} at ${variant.$3}',
        (tester) async {
      tester.view.physicalSize = Size(variant.$1, variant.$2);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = variant.$3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = ControlledAuth(AuthState(
          status: AuthStatus.authenticated,
          user: UserProfile(
              id: 'fixture',
              email: 'learner@example.test',
              displayName: 'Minh Anh',
              createdAt: DateTime(2026))));
      final api = ApiClient(
          config: const AppConfig(apiBaseUrl: 'https://api.test/api/v1'),
          accessToken: () => 'fixture',
          dio: Dio()
            ..httpClientAdapter = ScriptedAdapter((_, __) => jsonResponse({
                  'totalSessions': 0,
                  'totalMinutes': 0,
                  'currentStreakDays': 0
                })));
      final container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith((ref) => auth),
        apiClientProvider.overrideWithValue(api)
      ]);
      final router = container.read(appRouterProvider);
      router.go('/home');
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(
              key: ValueKey('academic-capture'), child: FluentTalkApp())));

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final contentWidth =
          tester.getSize(find.byType(ConnectedAreaScreen).first).width;
      expect(contentWidth,
          closeTo(variant.$1 >= 1080 ? variant.$1 - 244 : variant.$1, 1));
      if (variant.$3 == 1 && const bool.fromEnvironment('CAPTURE_UI')) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('academic-capture')))
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file =
              File('docs/qa/ui/academic-home-${variant.$1.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      api.close();
    });
  }
}
