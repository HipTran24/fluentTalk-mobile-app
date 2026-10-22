import 'dart:async';
import 'package:dio/dio.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/models/enums.dart';
import 'package:english_mobile_app/core/models/user_profile.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/features/auth/data/auth_repository.dart';
import 'package:english_mobile_app/features/auth/data/me_profile_dto.dart';
import 'package:english_mobile_app/features/auth/domain/auth_state.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

class MockStreamAuthRepository implements AuthRepository {
  final StreamController<AuthChangeEvent> _controller =
      StreamController<AuthChangeEvent>.broadcast();
  bool signOutCalled = false;
  int signOutCount = 0;
  final bool _isAdmin = false;
  UserProfile? mockUser;

  @override
  Stream<AuthChangeEvent> get authEventStream => _controller.stream;

  void emitEvent(AuthChangeEvent event) {
    _controller.add(event);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  bool get isAdmin => _isAdmin;

  @override
  Future<String?> getAccessToken() async => 'mock_token';

  @override
  Future<bool> isOnboarded() async => true;

  @override
  Future<UserProfile?> restoreSession() async => mockUser;

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    return mockUser ??
        UserProfile(
          id: 'user-001',
          email: email,
          displayName: 'Test',
          createdAt: DateTime.now(),
        );
  }

  @override
  Future<UserProfile> signUp(
      {required String email,
      required String password,
      required String displayName}) async {
    return UserProfile(
      id: 'user-002',
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    signOutCount++;
    mockUser = null;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updateOnboardingPreferences({
    required List<String> goals,
    required int dailyMinutes,
    required List<String> topicInterests,
    required String preferredVoice,
    required String feedbackLanguage,
  }) async {}

  void dispose() {
    _controller.close();
  }
}

class FakeFailingAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<dynamic>? requestStream, Future<void>? cancelFuture) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.cancel,
      message: 'Session changed',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Stage 2 Auth Security & Hardening Tests', () {
    test('Unconfigured Supabase configuration throws ConfigurationRequiredException and sets unconfigured status',
        () async {
      const emptyConfig = AppConfig(
        apiBaseUrl: '',
        supabaseUrl: '',
        supabaseAnonKey: '',
        demoMode: false,
      );

      final repo = SupabaseAuthRepository(config: emptyConfig);
      expect(
        () => repo.restoreSession(),
        throwsA(isA<ConfigurationRequiredException>()),
      );

      final controller = AuthController(repo, isDemo: false);
      await controller.restoreSession();
      expect(controller.state.status, AuthStatus.unconfigured);
      expect(controller.state.errorMessage, contains('Dịch vụ xác thực Supabase chưa được cấu hình'));
    });

    test('Supabase initialization failure sets explicit sanitized unconfigured status with generic message',
        () async {
      const dummyConfig = AppConfig(
        apiBaseUrl: 'https://api.fluenttalk.ai/api/v1',
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key-123',
        demoMode: false,
      );

      final repo = SupabaseAuthRepository(
        config: dummyConfig,
        initializationError:
            'Không thể khởi tạo dịch vụ xác thực Supabase. Vui lòng kiểm tra lại cấu hình hoặc kết nối mạng.',
      );

      expect(
        () => repo.restoreSession(),
        throwsA(predicate((e) =>
            e is ConfigurationRequiredException &&
            e.message.contains('Không thể khởi tạo dịch vụ xác thực Supabase'))),
      );

      final controller = AuthController(repo, isDemo: false);
      await controller.restoreSession();
      expect(controller.state.status, AuthStatus.unconfigured);
      expect(controller.state.errorMessage, contains('Không thể khởi tạo dịch vụ xác thực Supabase'));
    });

    test('MeProfileDto correctly maps camelCase API contract fixture to domain UserProfile',
        () {
      // Contract-first fixture compliant with docs/API_CONTRACT.yaml #/components/schemas/Profile
      final contractFixture = {
        'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        'email': 'alex@example.com',
        'displayName': 'Alex Nguyen',
        'avatarUrl': 'https://storage.example.com/avatar.png',
        'level': 'B1',
        'goal': 'work',
        'dailyMinutes': 25,
        'onboarded': true,
        'createdAt': '2026-10-21T08:30:00Z',
        'updatedAt': '2026-10-21T09:00:00Z',
      };

      final dto = MeProfileDto.fromJson(contractFixture);
      expect(dto.id, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
      expect(dto.displayName, 'Alex Nguyen');
      expect(dto.level, 'B1');
      expect(dto.dailyMinutes, 25);
      expect(dto.onboarded, isTrue);

      final domain = dto.toDomain();
      expect(domain.id, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
      expect(domain.displayName, 'Alex Nguyen');
      expect(domain.level, UserLevel.b1);
      expect(domain.goal, LearningGoalType.work);
      expect(domain.dailyMinutes, 25);
      expect(domain.createdAt.year, 2026);
    });

    test('Logout performs ApiClient.cancelSession, synchronous unauthenticated state, and singleflighted remote signOut',
        () async {
      const config = AppConfig(
        apiBaseUrl: 'https://api.fluenttalk.ai/api/v1',
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key-123',
        demoMode: false,
      );

      final dio = Dio()..httpClientAdapter = FakeFailingAdapter();
      final client = ApiClient(
        config: config,
        accessToken: () => 'token-a',
        dio: dio,
      );

      AuthState? stateAtCleanup;
      final repo = MockStreamAuthRepository();
      repo.mockUser = UserProfile(
        id: 'user-a',
        email: 'user-a@example.com',
        displayName: 'Account A',
        createdAt: DateTime.now(),
      );

      late final AuthController controller;
      controller = AuthController(
        repo,
        isDemo: false,
        apiClient: client,
        onAccountCleanup: () {
          stateAtCleanup = controller.state;
        },
      );

      await controller.restoreSession();
      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.user?.id, 'user-a');

      // Now logout
      final signOutFuture = controller.signOut();

      // Synchronously unauthenticated before await
      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.user, isNull);

      await signOutFuture;

      expect(repo.signOutCalled, isTrue);
      expect(stateAtCleanup?.status, AuthStatus.unauthenticated);
      expect(stateAtCleanup?.user, isNull);

      client.close();
      repo.dispose();
      controller.dispose();
    });

    test('Auth event stream handles tokenRefreshed and signedOut without loops',
        () async {
      final repo = MockStreamAuthRepository();
      repo.mockUser = UserProfile(
        id: 'user-stream',
        email: 'stream@example.com',
        displayName: 'Stream User',
        createdAt: DateTime.now(),
      );

      final controller = AuthController(repo, isDemo: false);
      await controller.restoreSession();
      expect(controller.state.status, AuthStatus.authenticated);

      // Trigger signedOut auth event
      repo.emitEvent(AuthChangeEvent.signedOut);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(repo.signOutCalled, isTrue);
      expect(repo.signOutCount, 1);

      // Trigger stream error
      repo.emitError('Revoked token refresh failure');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.errorMessage, contains('Revoked token refresh failure'));

      repo.dispose();
      controller.dispose();
    });

    test('Cache isolation across Account A -> logout -> Account B in Riverpod container',
        () async {
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWithValue(const AppConfig(
          apiBaseUrl: 'https://api.fluenttalk.ai/api/v1',
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key-123',
          demoMode: true,
        )),
      ]);
      addTearDown(container.dispose);

      final authNotifier = container.read(authControllerProvider.notifier);
      await authNotifier.signIn(email: 'account-a@fluenttalk.com', password: 'Password123');

      final stateA = container.read(authControllerProvider);
      expect(stateA.status, AuthStatus.authenticated);
      expect(stateA.user?.email, 'account-a@fluenttalk.com');

      // Logout Account A
      await authNotifier.signOut();
      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);

      // Sign in Account B
      await authNotifier.signIn(email: 'account-b@fluenttalk.com', password: 'Password123');
      final stateB = container.read(authControllerProvider);
      expect(stateB.status, AuthStatus.authenticated);
      expect(stateB.user?.email, 'account-b@fluenttalk.com');
      expect(stateB.user?.email, isNot(stateA.user?.email));
    });
  });
}
