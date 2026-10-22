import '../../../core/models/user_profile.dart';

/// Authentication Lifecycle Status
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsOnboarding,
  unconfigured,
  error,
}

/// State of Authentication & Current User Session
class AuthState {
  final AuthStatus status;
  final String? pendingConfirmationEmail;
  final UserProfile? user;
  final String? errorMessage;
  final bool isOffline;
  final bool isAdmin;
  final bool isDemo;
  final bool isConfigured;

  const AuthState({
    this.status = AuthStatus.initial,
    this.pendingConfirmationEmail,
    this.user,
    this.errorMessage,
    this.isOffline = false,
    this.isAdmin = false,
    this.isDemo = false,
    this.isConfigured = true,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsOnboarding => status == AuthStatus.needsOnboarding;
  bool get isLoading => status == AuthStatus.loading;
  bool get isUnconfigured => status == AuthStatus.unconfigured;

  AuthState copyWith({
    AuthStatus? status,
    String? pendingConfirmationEmail,
    bool clearPendingConfirmation = false,
    UserProfile? user,
    String? errorMessage,
    bool? isOffline,
    bool? isAdmin,
    bool? isDemo,
    bool? isConfigured,
  }) {
    return AuthState(
      status: status ?? this.status,
      pendingConfirmationEmail: clearPendingConfirmation
          ? null
          : pendingConfirmationEmail ?? this.pendingConfirmationEmail,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
      isAdmin: isAdmin ?? this.isAdmin,
      isDemo: isDemo ?? this.isDemo,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}
