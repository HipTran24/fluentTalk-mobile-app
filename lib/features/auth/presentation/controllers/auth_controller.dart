import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import '../../../../core/config/app_config.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/network/api_client.dart';
import '../../../coach/presentation/controllers/coach_controller.dart';
import '../../../conversation/presentation/controllers/chat_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../progress/presentation/controllers/progress_controller.dart';
import '../../../scenarios/presentation/controllers/scenario_controller.dart';
import '../../data/auth_repository.dart';
import '../../data/me_profile_dto.dart';
import '../../domain/auth_state.dart';

final Provider<AppConfig> appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final Provider<String?> supabaseInitErrorProvider =
    Provider<String?>((ref) => null);

final Provider<ApiClient?> apiClientProvider = Provider<ApiClient?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasBackend) return null;
  final authRepo = ref.watch(authRepositoryProvider);
  final client = ApiClient(
    config: config,
    accessToken: () => authRepo.getAccessToken(),
    onUnauthorized: () async {
      await authRepo.signOut();
    },
  );
  ref.onDispose(() {
    client.close();
  });
  return client;
});

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.demoMode) {
    return LocalAuthRepository();
  }
  final initError = ref.watch(supabaseInitErrorProvider);
  return SupabaseAuthRepository(
    config: config,
    initializationError: initError,
  );
});

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final config = ref.watch(appConfigProvider);
  final client = ref.watch(apiClientProvider);

  return AuthController(
    repo,
    isDemo: config.demoMode,
    apiClient: client,
    onAccountCleanup: () {
      // 1. Home & Conversation
      ref.invalidate(homeDashboardControllerProvider);
      ref.invalidate(chatControllerProvider);

      // 2. Progress & History
      ref.invalidate(progressPeriodProvider);
      ref.invalidate(progressAnalyticsControllerProvider);
      ref.invalidate(historyFilterModeProvider);
      ref.invalidate(historySearchQueryProvider);
      ref.invalidate(practiceHistoryControllerProvider);

      // 3. Profile & Vocab
      ref.invalidate(vocabularyFilterProvider);
      ref.invalidate(vocabularyListProvider);
      ref.invalidate(profileSettingsControllerProvider);

      // 4. Coach & Weekly Plan
      ref.invalidate(coachWeaknessesProvider);
      ref.invalidate(weeklyPlanProvider);

      // 5. Scenario Filters & Catalog
      ref.invalidate(selectedTopicIdProvider);
      ref.invalidate(selectedLevelProvider);
      ref.invalidate(searchQueryProvider);
      ref.invalidate(selectedCatalogTabProvider);
      ref.invalidate(filteredScenariosProvider);
      ref.invalidate(catalogPageIndexProvider);
      ref.invalidate(catalogPageProvider);
    },
  );
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final bool isDemo;
  final ApiClient? apiClient;
  final void Function()? onAccountCleanup;

  int _epoch = 0;
  Future<void>? _signOutFuture;
  StreamSubscription<AuthChangeEvent>? _authSubscription;

  AuthController(
    this._repository, {
    this.isDemo = false,
    this.apiClient,
    this.onAccountCleanup,
  }) : super(AuthState(isDemo: isDemo)) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _repository.authEventStream.listen(
      (event) async {
        if (event == AuthChangeEvent.tokenRefreshed) {
          if ((state.isAuthenticated || state.needsOnboarding) &&
              state.user != null) {
            await syncProfileFromBackend();
          }
        } else if (event == AuthChangeEvent.signedOut) {
          if (_signOutFuture != null ||
              state.status == AuthStatus.unauthenticated) {
            // Already signing out or already unauthenticated; avoid reentering
            return;
          }
          await signOut();
        }
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: 'Phiên xác thực gặp lỗi. Hãy đăng nhập lại.',
        );
      },
    );
  }

  Future<void> syncProfileFromBackend() async {
    if (apiClient == null || isDemo) return;
    final opEpoch = _epoch;
    try {
      final res = await apiClient!.get('me');
      if (!mounted || opEpoch != _epoch) return;
      if (res is Map<String, dynamic>) {
        final profile = MeProfileDto.fromJson(res);
        state = state.copyWith(
            user: profile.toDomain(),
            status: profile.onboarded == null
                ? state.status
                : profile.onboarded == true
                    ? AuthStatus.authenticated
                    : AuthStatus.needsOnboarding);
      }
    } catch (_) {
      // Fail-soft on profile background sync
    }
  }

  Future<void> restoreSession() async {
    final opEpoch = _epoch;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.restoreSession();
      if (!mounted || opEpoch != _epoch) return;

      if (user != null) {
        UserProfile effectiveUser = user;
        bool? backendOnboarded;
        if (apiClient != null && !isDemo) {
          try {
            final res = await apiClient!.get('me');
            if (!mounted || opEpoch != _epoch) return;
            if (res is Map<String, dynamic>) {
              final profile = MeProfileDto.fromJson(res);
              effectiveUser = profile.toDomain();
              backendOnboarded = profile.onboarded;
            }
          } catch (_) {}
        }
        final onboarded = backendOnboarded ?? await _repository.isOnboarded();
        if (!mounted || opEpoch != _epoch) return;

        state = state.copyWith(
          status:
              onboarded ? AuthStatus.authenticated : AuthStatus.needsOnboarding,
          user: effectiveUser,
          isAdmin: _repository.isAdmin,
          isDemo: isDemo,
        );
      } else {
        if (!mounted || opEpoch != _epoch) return;
        state =
            state.copyWith(status: AuthStatus.unauthenticated, isDemo: isDemo);
      }
    } on ConfigurationRequiredException catch (e) {
      if (!mounted || opEpoch != _epoch) return;
      state = state.copyWith(
        status: AuthStatus.unconfigured,
        errorMessage: e.message,
        isDemo: isDemo,
      );
    } catch (e) {
      if (!mounted || opEpoch != _epoch) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
        isDemo: isDemo,
      );
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    final opEpoch = _epoch;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signIn(email: email, password: password);
      if (!mounted || opEpoch != _epoch) return false;

      UserProfile effectiveUser = user;
      bool? backendOnboarded;
      if (apiClient != null && !isDemo) {
        try {
          final res = await apiClient!.get('me');
          if (!mounted || opEpoch != _epoch) return false;
          if (res is Map<String, dynamic>) {
            final profile = MeProfileDto.fromJson(res);
            effectiveUser = profile.toDomain();
            backendOnboarded = profile.onboarded;
          }
        } catch (_) {}
      }
      final onboarded = backendOnboarded ?? await _repository.isOnboarded();
      if (!mounted || opEpoch != _epoch) return false;

      state = state.copyWith(
        status:
            onboarded ? AuthStatus.authenticated : AuthStatus.needsOnboarding,
        user: effectiveUser,
        isAdmin: _repository.isAdmin,
        isDemo: isDemo,
      );
      return true;
    } on ConfigurationRequiredException catch (e) {
      if (!mounted || opEpoch != _epoch) return false;
      state = state.copyWith(
        status: AuthStatus.unconfigured,
        errorMessage: e.message,
        isDemo: isDemo,
      );
      return false;
    } catch (e) {
      if (!mounted || opEpoch != _epoch) return false;
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
        isDemo: isDemo,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final opEpoch = _epoch;
    state = state.copyWith(
        status: AuthStatus.loading,
        errorMessage: null,
        clearPendingConfirmation: true);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (!mounted || opEpoch != _epoch) return false;

      if (!isDemo && await _repository.getAccessToken() == null) {
        if (!mounted || opEpoch != _epoch) return false;
        state = state.copyWith(
            status: AuthStatus.unauthenticated,
            pendingConfirmationEmail: email.trim(),
            errorMessage:
                'Nếu đăng ký thành công, hãy kiểm tra email xác nhận rồi quay lại đăng nhập.');
        return false;
      }
      if (!mounted || opEpoch != _epoch) return false;

      state = state.copyWith(
        status: AuthStatus.needsOnboarding,
        user: user,
        isAdmin: false,
        isDemo: isDemo,
      );
      return true;
    } on ConfigurationRequiredException catch (e) {
      if (!mounted || opEpoch != _epoch) return false;
      state = state.copyWith(
        status: AuthStatus.unconfigured,
        errorMessage: e.message,
        isDemo: isDemo,
      );
      return false;
    } catch (e) {
      if (!mounted || opEpoch != _epoch) return false;
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
        isDemo: isDemo,
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
    final opEpoch = _epoch;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.updateOnboardingPreferences(
        goals: goals,
        dailyMinutes: dailyMinutes,
        topicInterests: topicInterests,
        preferredVoice: preferredVoice,
        feedbackLanguage: feedbackLanguage,
      );
      if (!mounted || opEpoch != _epoch) return;

      final user = state.user?.copyWith(dailyMinutes: dailyMinutes);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      if (!mounted || opEpoch != _epoch) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
    }
  }

  Future<void> signOut() {
    if (_signOutFuture != null) {
      return _signOutFuture!;
    }

    _epoch++;

    // 1. Set signed-out state SYNCHRONOUSLY before any await or cleanup
    state = const AuthState(status: AuthStatus.unauthenticated);

    // 2. Cancel in-flight network requests
    apiClient?.cancelSession();

    // 3. Invalidate account caches & media while state is already unauthenticated
    onAccountCleanup?.call();

    // 4. Remote repository signOut (singleflighted so reentering from signedOut event returns the same future)
    final future = _signOutFuture = Future<void>(() async {
      try {
        await _repository.signOut();
      } catch (_) {}
    }).whenComplete(() {
      _signOutFuture = null;
    });

    return future;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
