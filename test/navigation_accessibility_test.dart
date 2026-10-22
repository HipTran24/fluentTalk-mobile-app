import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_mobile_app/app/router/app_router.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/models/user_profile.dart';
import 'package:english_mobile_app/features/auth/data/auth_repository.dart';
import 'package:english_mobile_app/features/auth/domain/auth_state.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:english_mobile_app/main.dart';

class NavigationAuth extends AuthController {
  NavigationAuth() : super(LocalAuthRepository(), isDemo: true) {
    state = AuthState(
        status: AuthStatus.authenticated,
        isDemo: true,
        user: UserProfile(
            id: 'demo-navigation',
            email: 'demo@example.test',
            displayName: 'Demo',
            createdAt: DateTime(2026)));
  }
  @override
  Future<void> restoreSession() async {}
}

void main() {
  testWidgets('all five tabs remain usable at 320dp with enlarged text',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(overrides: [
      appConfigProvider.overrideWithValue(const AppConfig(demoMode: true)),
      authControllerProvider.overrideWith((ref) => NavigationAuth()),
    ]);
    final router = container.read(appRouterProvider);
    router.go('/home');
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const FluentTalkApp()));
    for (final index in [0, 1, 2, 3, 4, 0]) {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
      final destination = find.byType(NavigationDestination).at(index);
      await tester.tap(destination);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    container.dispose();
    expect(tester.takeException(), isNull);
  });
}
