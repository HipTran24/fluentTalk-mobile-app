import 'package:english_mobile_app/app/router/app_router.dart';
import 'package:english_mobile_app/features/auth/data/auth_repository.dart';
import 'package:english_mobile_app/features/auth/domain/auth_state.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledAuth extends AuthController {
  ControlledAuth(AuthState initial)
      : super(LocalAuthRepository(), isDemo: true) {
    state = initial;
  }

  void update(AuthState next) => state = next;

  @override
  Future<void> restoreSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'public catalog is reachable without granting session or admin access',
      (tester) async {
    final auth =
        ControlledAuth(const AuthState(status: AuthStatus.unauthenticated));
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => auth),
    ]);
    final router = container.read(appRouterProvider);
    router.go('/practice/scenarios');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/practice/scenarios');
    router.go('/practice/scenario/10000000-0000-0000-0000-000000000001');
    await tester.pump();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/practice/scenario/10000000-0000-0000-0000-000000000001');
    for (final protected in [
      '/practice/text',
      '/practice/guided/123',
      '/practice/realtime/123',
      '/admin'
    ]) {
      router.go(protected);
      await tester.pump();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/welcome');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    container.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('real account cannot enter simulated learning screens',
      (tester) async {
    final auth = ControlledAuth(const AuthState(
      status: AuthStatus.authenticated,
      isDemo: false,
    ));
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => auth),
    ]);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    for (final path in ['/home', '/practice/text', '/coach', '/profile']) {
      router.go(path);
      await tester.pump();
      await tester.pump();
      expect(
          router.routerDelegate.currentConfiguration.uri.path, '/unavailable',
          reason: path);
    }
    expect(find.text('Chế độ học chưa sẵn sàng'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    container.dispose();
    expect(tester.takeException(), isNull);
  });

  test('auth changes refresh the same router without replacing its navigator',
      () {
    final auth = ControlledAuth(const AuthState(status: AuthStatus.loading));
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => auth),
    ]);
    addTearDown(container.dispose);
    final original = container.read(appRouterProvider);
    auth.update(const AuthState(status: AuthStatus.unauthenticated));
    expect(identical(original, container.read(appRouterProvider)), isTrue);
    auth.update(const AuthState(status: AuthStatus.loading));
    expect(identical(original, container.read(appRouterProvider)), isTrue);
  });

  testWidgets('loading identity cannot open admin even with stale admin flag',
      (tester) async {
    final auth = ControlledAuth(const AuthState(
      status: AuthStatus.loading,
      isAdmin: true,
    ));
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => auth),
    ]);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    for (final path in ['/admin', '/profile', '/progress/history']) {
      router.go(path);
      await tester.pump();
      await tester.pump();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/splash',
          reason: path);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    container.dispose();
    expect(tester.takeException(), isNull);
  });
}
