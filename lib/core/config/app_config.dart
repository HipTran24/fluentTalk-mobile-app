/// Public mobile configuration only. Provider and service-role keys belong on
/// the backend and must never be passed through Dart defines.
class AppConfig {
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool demoMode;
  final bool allowInsecureLocalhost;

  const AppConfig({
    this.apiBaseUrl = '',
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.demoMode = false,
    this.allowInsecureLocalhost = false,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
        apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
        demoMode: bool.fromEnvironment('DEMO_MODE'),
        allowInsecureLocalhost:
            bool.fromEnvironment('ALLOW_INSECURE_LOCALHOST'),
      );

  bool get hasBackend => _validEndpoint(apiBaseUrl, api: true);
  bool get hasAuth =>
      _validEndpoint(supabaseUrl) && supabaseAnonKey.trim().isNotEmpty;
  bool get isProductionConfigured => !demoMode && hasBackend && hasAuth;

  List<String> get missingConfiguration => [
        if (!hasBackend) 'API_BASE_URL',
        if (!hasAuth) 'SUPABASE_URL / SUPABASE_ANON_KEY',
      ];

  bool _validEndpoint(String value, {bool api = false}) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return false;
    }
    const loopbackHosts = {'localhost', '127.0.0.1', '::1', '10.0.2.2'};
    final secure = uri.scheme == 'https' ||
        (allowInsecureLocalhost &&
            uri.scheme == 'http' &&
            loopbackHosts.contains(uri.host));
    if (!secure) return false;
    return !api || uri.path.replaceAll(RegExp(r'/+$'), '') == '/api/v1';
  }

  /// Do not include public keys or URLs in diagnostic output by accident.
  @override
  String toString() => 'AppConfig(demoMode: $demoMode, '
      'backendConfigured: $hasBackend, authConfigured: $hasAuth)';
}
