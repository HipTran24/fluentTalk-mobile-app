import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        final onboarded = await _repository.isOnboarded();
        state = state.copyWith(
          status: onboarded ? AuthStatus.authenticated : AuthStatus.needsOnboarding,
          user: user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Lỗi khôi phục phiên đăng nhập: $e',
      );
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signIn(email: email, password: password);
      final onboarded = await _repository.isOnboarded();
      state = state.copyWith(
        status: onboarded ? AuthStatus.authenticated : AuthStatus.needsOnboarding,
        user: user,
      );
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(
        status: AuthStatus.needsOnboarding,
        user: user,
      );
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: message);
      return false;
    }
  }

  Future<void> completeOnboarding({
    required List<String> goals,
    required int dailyMinutes,
    required List<String> topicInterests,
    required String preferredVoice,
    required String feedbackLanguage,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.updateOnboardingPreferences(
        goals: goals,
        dailyMinutes: dailyMinutes,
        topicInterests: topicInterests,
        preferredVoice: preferredVoice,
        feedbackLanguage: feedbackLanguage,
      );
      final user = state.user?.copyWith(dailyMinutes: dailyMinutes);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated, // Fallback to allow continuing
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
