import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_mobile_app/features/auth/data/auth_repository.dart';
import 'package:english_mobile_app/features/auth/domain/auth_state.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthRepository & Persistence Tests', () {
    test('signUp creates user and stores un-onboarded state', () async {
      final repo = LocalAuthRepository();
      final user = await repo.signUp(
        email: 'test@example.com',
        password: 'Password123',
        displayName: 'Test User',
      );

      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');

      final isOnboarded = await repo.isOnboarded();
      expect(isOnboarded, false);

      final restored = await repo.restoreSession();
      expect(restored, isNotNull);
      expect(restored!.email, 'test@example.com');
    });

    test('signIn authenticates user and sets session', () async {
      final repo = LocalAuthRepository();
      final user = await repo.signIn(
        email: 'learner@fluenttalk.com',
        password: 'ValidPassword123',
      );

      expect(user.email, 'learner@fluenttalk.com');
      final isOnboarded = await repo.isOnboarded();
      expect(isOnboarded, true);
    });

    test('signOut removes persisted session', () async {
      final repo = LocalAuthRepository();
      await repo.signIn(
        email: 'logout@test.com',
        password: 'Password123',
      );

      await repo.signOut();
      final restored = await repo.restoreSession();
      expect(restored, isNull);
    });

    test(
        'updateOnboardingPreferences updates dailyMinutes and onboarded status',
        () async {
      final repo = LocalAuthRepository();
      await repo.signUp(
        email: 'onboard@test.com',
        password: 'Password123',
        displayName: 'New Learner',
      );

      await repo.updateOnboardingPreferences(
        goals: ['daily', 'work'],
        dailyMinutes: 20,
        topicInterests: ['Công nghệ'],
        preferredVoice: 'en-US-Journey-F',
        feedbackLanguage: 'vi',
      );

      final isOnboarded = await repo.isOnboarded();
      expect(isOnboarded, true);

      final restored = await repo.restoreSession();
      expect(restored?.dailyMinutes, 20);
    });
  });

  group('AuthController Riverpod StateNotifier Tests', () {
    test('Initial state is uninitialized', () {
      final repo = LocalAuthRepository();
      final controller = AuthController(repo);
      expect(controller.state.status, AuthStatus.initial);
    });

    test('restoreSession transitions to unauthenticated when empty', () async {
      final repo = LocalAuthRepository();
      final controller = AuthController(repo);

      await controller.restoreSession();
      expect(controller.state.status, AuthStatus.unauthenticated);
    });

    test('signUp transitions to needsOnboarding', () async {
      final repo = LocalAuthRepository();
      final controller = AuthController(repo);

      final success = await controller.signUp(
        email: 'hello@world.com',
        password: 'Password123',
        displayName: 'Hello',
      );

      expect(success, true);
      expect(controller.state.status, AuthStatus.needsOnboarding);
      expect(controller.state.user?.email, 'hello@world.com');
    });
  });
}
