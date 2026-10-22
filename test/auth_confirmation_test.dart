import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/models/user_profile.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/features/auth/data/auth_repository.dart';
import 'package:english_mobile_app/features/auth/domain/auth_state.dart';
import 'package:english_mobile_app/features/auth/presentation/controllers/auth_controller.dart';
import 'api_client_test.dart' show ScriptedAdapter, jsonResponse;

class ConfirmationRepository extends LocalAuthRepository {
  String? token;
  ConfirmationRepository(this.token);
  final user = UserProfile(
      id: '10000000-0000-0000-0000-000000000001',
      email: 'fixture@example.test',
      displayName: 'Fixture',
      createdAt: DateTime(2026));
  @override
  Future<UserProfile> signUp(
          {required String email,
          required String password,
          required String displayName}) async =>
      user;
  @override
  Future<UserProfile> signIn(
          {required String email, required String password}) async =>
      user;
  @override
  Future<String?> getAccessToken() async => token;
  @override
  Future<bool> isOnboarded() async => false;
}

void main() {
  test(
      'signup without a Supabase session stays signed out pending email confirmation',
      () async {
    final controller = AuthController(ConfirmationRepository(null));
    addTearDown(controller.dispose);
    expect(
        await controller.signUp(
            email: 'fixture@example.test',
            password: 'fixture-password',
            displayName: 'Fixture'),
        isFalse);
    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(controller.state.errorMessage, contains('email xác nhận'));
    expect(controller.state.pendingConfirmationEmail, 'fixture@example.test');
  });

  test('backend onboarded flag takes precedence over stale local preferences',
      () async {
    final adapter = ScriptedAdapter((_, __) => jsonResponse({
          'id': '10000000-0000-0000-0000-000000000001',
          'email': 'fixture@example.test',
          'displayName': 'Đã đồng bộ',
          'level': 'B1',
          'dailyMinutes': 20,
          'onboarded': true,
          'createdAt': '2026-10-22T00:00:00Z',
        }));
    final api = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.test/api/v1'),
        accessToken: () => 'fixture',
        dio: Dio()..httpClientAdapter = adapter);
    addTearDown(api.close);
    final controller =
        AuthController(ConfirmationRepository('fixture'), apiClient: api);
    addTearDown(controller.dispose);
    expect(
        await controller.signIn(
            email: 'fixture@example.test', password: 'fixture'),
        isTrue);
    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.user?.displayName, 'Đã đồng bộ');
  });
}
