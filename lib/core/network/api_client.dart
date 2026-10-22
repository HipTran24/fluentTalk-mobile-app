import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_failure.dart';

typedef AccessTokenReader = FutureOr<String?> Function();

/// A scoped API transport. It never retries mutations automatically. Callers
/// retain the same idempotency key when the user explicitly retries a turn.
/// A new session epoch prevents stale responses reaching a different account.
class ApiClient {
  final Dio _dio;
  final AccessTokenReader _accessToken;
  final FutureOr<void> Function()? _onUnauthorized;
  CancelToken _sessionCancellation = CancelToken();
  int _epoch = 0;
  bool _closed = false;
  Future<void>? _unauthorizedFuture;

  ApiClient({
    required AppConfig config,
    required AccessTokenReader accessToken,
    FutureOr<void> Function()? onUnauthorized,
    Dio? dio,
  })  : _accessToken = accessToken,
        _onUnauthorized = onUnauthorized,
        _dio = dio ?? Dio() {
    if (!config.hasBackend) {
      throw const ApiFailure(
        code: 'CONFIGURATION_REQUIRED',
        message: 'Ứng dụng chưa được cấu hình kết nối máy chủ.',
      );
    }
    // This transport is account-scoped. Callers may inject an adapter for
    // testing, but inherited interceptors must not observe bearer credentials.
    _dio.interceptors.clear();
    _dio.options = BaseOptions(
      baseUrl: '${config.apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/',
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
      // Authenticated redirects must not carry credentials to another origin.
      followRedirects: false,
    );
  }

  static String newIdempotencyKey() {
    final random = Random.secure();
    return List.generate(
            24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<Object?> get(String path,
          {Map<String, dynamic>? query, bool authenticated = true}) =>
      request('GET', path, query: query, authenticated: authenticated);

  Future<Object?> post(String path, {Object? data, String? idempotencyKey}) =>
      request('POST', path, data: data, idempotencyKey: idempotencyKey);

  Future<Object?> patch(String path, {Object? data}) =>
      request('PATCH', path, data: data);

  Future<Object?> delete(String path) => request('DELETE', path);

  Future<Object?> request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    String? idempotencyKey,
    bool authenticated = true,
  }) async {
    _checkOpen();
    final route = _safeRoute(path);
    final epoch = _epoch;
    final cancelToken = _sessionCancellation;
    final verb = method.toUpperCase();
    if (!{'GET', 'POST', 'PATCH', 'DELETE', 'PUT'}.contains(verb)) {
      throw ArgumentError.value(method, 'method', 'Unsupported HTTP method');
    }
    if (idempotencyKey != null &&
        !RegExp(r'^[A-Za-z0-9_-]{8,128}$').hasMatch(idempotencyKey)) {
      throw ArgumentError('Invalid idempotency key');
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      _ensureEpoch(epoch);
      String? token;
      try {
        token = authenticated ? await _accessToken() : null;
      } catch (_) {
        _ensureEpoch(epoch);
        throw const ApiFailure(
          code: 'SESSION_UNAVAILABLE',
          message: 'Không thể khôi phục phiên. Hãy đăng nhập lại.',
        );
      }
      _ensureEpoch(epoch);
      if (authenticated && (token == null || token.isEmpty)) {
        throw const ApiFailure(
          code: 'UNAUTHENTICATED',
          message: 'Hãy đăng nhập để tiếp tục.',
          statusCode: 401,
        );
      }
      try {
        final response = await _dio.request<Object?>(
          route,
          data: data,
          queryParameters: query,
          cancelToken: cancelToken,
          options: Options(method: verb, headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
          }),
        );
        _ensureEpoch(epoch);
        return response.data;
      } on DioException catch (error) {
        _ensureEpoch(epoch);
        final failure = ApiFailure.fromDio(error);
        if (failure.statusCode == 401) {
          await _handleUnauthorized();
          _ensureEpoch(epoch);
        }
        if (verb == 'GET' && failure.canRetry && attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }
        throw failure;
      }
    }
    throw StateError('Unreachable request state');
  }

  String _safeRoute(String path) {
    final uri = Uri.tryParse(path);
    String decoded;
    try {
      decoded = Uri.decodeComponent(path);
    } on FormatException {
      throw ArgumentError('Malformed API path');
    }
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        path.startsWith('//') ||
        decoded.contains('\\') ||
        decoded.split('/').any((part) => part == '..' || part == '.')) {
      throw ArgumentError('API path must stay within the configured origin');
    }
    final route = path.replaceFirst(RegExp(r'^/'), '');
    if (route.isEmpty) throw ArgumentError('API path cannot be empty');
    return route;
  }

  void _checkOpen() {
    if (_closed) {
      throw const ApiFailure(code: 'CANCELLED', message: 'Kết nối đã đóng.');
    }
  }

  Future<void> _handleUnauthorized() async {
    final pending = _unauthorizedFuture;
    if (pending != null) return pending;
    // Callback failures must not expose auth SDK internals or replace the
    // original safe HTTP failure. All concurrent 401s await this same cleanup.
    final operation = Future<void>.sync(() => _onUnauthorized?.call())
        .catchError((Object _) {});
    _unauthorizedFuture = operation;
    try {
      await operation;
    } finally {
      _unauthorizedFuture = null;
    }
  }

  void _ensureEpoch(int epoch) {
    _checkOpen();
    if (_epoch != epoch) {
      throw const ApiFailure(code: 'CANCELLED', message: 'Phiên đã thay đổi.');
    }
  }

  /// Invoke before clearing auth on logout or changing the signed-in account.
  void cancelSession() {
    _epoch++;
    _sessionCancellation.cancel('Session changed');
    _sessionCancellation = CancelToken();
  }

  void close() {
    if (_closed) return;
    cancelSession();
    _closed = true;
    _dio.close(force: true);
  }
}
