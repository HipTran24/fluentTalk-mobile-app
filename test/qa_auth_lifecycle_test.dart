import 'dart:async';

import 'package:english_mobile_app/core/models/user_profile.dart';
import 'package:english_mobile_app/features/auth/data/auth_repository.dart';
import 'package:english_mobile_app/features/auth/domain/auth_state.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

class LifecycleRepository extends LocalAuthRepository {
  final events = StreamController<AuthChangeEvent>.broadcast();
  Future<UserProfile?>? pendingRestore;
  Future<UserProfile>? pendingSignIn;
  int signOutCalls = 0;

  final user = UserProfile(
    id: '6e21fafe-3ee9-49aa-891b-67dcf8eb4c11',
    email: 'fixture@example.test',
    displayName: 'Fixture',
    createdAt: DateTime.utc(2026),
  );

  @override
  Stream<AuthChangeEvent> get authEventStream => events.stream;

  @override
  Future<UserProfile?> restoreSession() async => pendingRestore;

  @override
  Future<UserProfile> signIn(
          {required String email, required String password}) async =>
      pendingSignIn ?? Future.value(user);

  @override
  Future<bool> isOnboarded() async => true;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutCalls == 1) events.add(AuthChangeEvent.signedOut);
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late LifecycleRepository repo;
  late AuthController controller;

  setUp(() {
    repo = LifecycleRepository();
    controller = AuthController(repo);
  });
  tearDown(() async {
    controller.dispose();
    await repo.events.close();
  });

  test('pending restore cannot resurrect an account after logout', () async {
    final response = Completer<UserProfile?>();
    repo.pendingRestore = response.future;
    final pending = controller.restoreSession();
    await controller.signOut();
    response.complete(repo.user);
    await pending;
    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(controller.state.user, isNull);
    expect(controller.state.isAdmin, isFalse);
  });

  test('pending sign in cannot resurrect an account after logout', () async {
    final response = Completer<UserProfile>();
    repo.pendingSignIn = response.future;
    final pending =
        controller.signIn(email: 'fixture@example.test', password: 'fixture');
    await controller.signOut();
    response.complete(repo.user);
    expect(await pending, isFalse);
    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(controller.state.user, isNull);
  });

  test('signedOut event does not reenter remote logout', () async {
    await controller.signIn(email: 'fixture@example.test', password: 'fixture');
    await controller.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(repo.signOutCalls, 1);
    expect(controller.state.status, AuthStatus.unauthenticated);
  });

  test('account state is cleared before scoped caches rebuild', () async {
    controller.dispose();
    AuthState? stateAtCleanup;
    controller = AuthController(repo, onAccountCleanup: () {
      stateAtCleanup = controller.state;
    });
    await controller.signIn(email: 'fixture@example.test', password: 'fixture');
    await controller.signOut();
    expect(stateAtCleanup?.status, AuthStatus.unauthenticated);
    expect(stateAtCleanup?.user, isNull);
  });
}
