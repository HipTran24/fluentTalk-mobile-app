import '../../../core/models/user_profile.dart';

/// Authentication Lifecycle Status
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsOnboarding,
  error,
}

/// State of Authentication & Current User Session
class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;
  final bool isOffline;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isOffline = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsOnboarding => status == AuthStatus.needsOnboarding;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
    bool? isOffline,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
