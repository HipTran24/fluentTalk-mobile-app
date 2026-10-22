import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/core/config/app_config.dart';
import 'package:english_mobile_app/core/network/api_client.dart';
import 'package:english_mobile_app/core/network/api_failure.dart';

class ScriptedAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions, int) respond;
  final List<RequestOptions> requests = [];
  ScriptedAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return respond(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object data, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });

const configured = AppConfig(apiBaseUrl: 'https://api.example.test/api/v1');

void main() {
  group('Public configuration boundaries', () {
    test('requires secure explicit origins and exact API version', () {
      expect(const AppConfig().hasBackend, isFalse);
      expect(configured.hasBackend, isTrue);
      for (final bad in [
        'http://api.example.test/api/v1',
        'https://token@api.example.test/api/v1',
        'https://api.example.test/api/v2',
        'https://api.example.test/api/v1?secret=x',
      ]) {
        expect(AppConfig(apiBaseUrl: bad).hasBackend, isFalse, reason: bad);
      }
      expect(
          const AppConfig(
                  apiBaseUrl: 'http://10.0.2.2:8080/api/v1',
                  allowInsecureLocalhost: true)
              .hasBackend,
          isTrue);
      expect(
          const AppConfig(
                  apiBaseUrl: 'http://192.168.1.7:8080/api/v1',
                  allowInsecureLocalhost: true)
              .hasBackend,
          isFalse);
    });

    test('diagnostic output excludes key material', () {
      const config = AppConfig(supabaseAnonKey: 'never-print-this');
      expect(config.toString(), isNot(contains('never-print-this')));
    });
  });

  group('Authenticated transport', () {
    late Dio dio;
    late ScriptedAdapter adapter;
    late ApiClient client;

    void create(FutureOr<ResponseBody> Function(RequestOptions, int) respond,
        {AccessTokenReader? token, FutureOr<void> Function()? unauthorized}) {
      dio = Dio();
      adapter = ScriptedAdapter(respond);
      dio.httpClientAdapter = adapter;
      client = ApiClient(
        config: configured,
        accessToken: token ?? () => 'session-token',
        onUnauthorized: unauthorized,
        dio: dio,
      );
      addTearDown(client.close);
    }

    test('rejects credential exfiltration and version traversal before HTTP',
        () async {
      create((_, __) => jsonResponse({}));
      for (final path in [
        'https://other.test/token',
        '//other.test/token',
        '../admin',
        '%2e%2e/admin',
        '/sessions/../../admin',
        r'\other.test\token',
        'sessions?token=oops',
        'sessions/%',
      ]) {
        await expectLater(client.get(path), throwsArgumentError, reason: path);
      }
      expect(adapter.requests, isEmpty);
    });

    test('confines leading slash routes to api/v1 and disables redirects',
        () async {
      create((_, __) => jsonResponse({'status': 'UP'}));
      await client.get('/health', authenticated: false);
      final request = adapter.requests.single;
      expect(request.uri.toString(), 'https://api.example.test/api/v1/health');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.followRedirects, isFalse);
    });

    test('missing token fails before network', () async {
      create((_, __) => jsonResponse({}), token: () => null);
      await expectLater(
          client.get('me'),
          throwsA(isA<ApiFailure>()
              .having((e) => e.code, 'code', 'UNAUTHENTICATED')));
      expect(adapter.requests, isEmpty);
    });

    test('retries safe read once and refreshes token per attempt', () async {
      var tokenReads = 0;
      create((_, attempt) => jsonResponse({}, attempt == 1 ? 503 : 200),
          token: () => 'token-${++tokenReads}');
      await client.get('scenarios');
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.headers['Authorization'], 'Bearer token-2');
    });

    test('never automatically replays failed mutation or loses its key',
        () async {
      create((_, __) => jsonResponse({'code': 'UPSTREAM_UNAVAILABLE'}, 503));
      const key = 'turn-retry-key-0001';
      await expectLater(
          client.post('sessions', data: {'mode': 'text'}, idempotencyKey: key),
          throwsA(
              isA<ApiFailure>().having((e) => e.canRetry, 'retry', isTrue)));
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.headers['Idempotency-Key'], key);
    });

    test('unauthorized invokes one handler and excludes upstream secrets',
        () async {
      var authFailures = 0;
      create(
          (_, __) => jsonResponse({
                'code': 'INVALID_TOKEN',
                'message': 'backend secret: abc',
                'requestId': 'req-123'
              }, 401),
          unauthorized: () => authFailures++);
      await expectLater(
          client.get('me'),
          throwsA(isA<ApiFailure>()
              .having((e) => e.code, 'code', 'UNAUTHENTICATED')
              .having(
                  (e) => e.message, 'safe message', isNot(contains('secret')))
              .having((e) => e.requestId, 'request id', 'req-123')));
      expect(authFailures, 1);
      expect(adapter.requests, hasLength(1));
    });

    test('quota is not automatically retried', () async {
      create((_, __) => jsonResponse({}, 429));
      await expectLater(
          client.get('me'),
          throwsA(isA<ApiFailure>()
              .having((e) => e.code, 'code', 'QUOTA_EXCEEDED')));
      expect(adapter.requests, hasLength(1));
    });

    test('auth SDK failures are typed and do not leak credentials', () async {
      create((_, __) => jsonResponse({}),
          token: () => throw StateError('secret-token-value'));
      await expectLater(
          client.get('me'),
          throwsA(isA<ApiFailure>()
              .having((e) => e.code, 'code', 'SESSION_UNAVAILABLE')
              .having((e) => e.toString(), 'redacted',
                  isNot(contains('secret-token-value')))));
      expect(adapter.requests, isEmpty);
    });

    test('failing unauthorized handler preserves safe HTTP failure', () async {
      create((_, __) => jsonResponse({}, 401),
          unauthorized: () => throw StateError('internal-secret'));
      await expectLater(
          client.get('me'),
          throwsA(isA<ApiFailure>()
              .having((e) => e.code, 'code', 'UNAUTHENTICATED')));
    });

    test('concurrent unauthorized requests await one cleanup', () async {
      final cleanup = Completer<void>();
      var count = 0;
      create((_, __) => jsonResponse({}, 401), unauthorized: () {
        count++;
        return cleanup.future;
      });
      final first = expectLater(client.get('me'), throwsA(isA<ApiFailure>()));
      final second =
          expectLater(client.get('sessions'), throwsA(isA<ApiFailure>()));
      while (adapter.requests.length < 2 || count == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(Duration.zero);
      expect(count, 1);
      cleanup.complete();
      await Future.wait([first, second]);
    });

    test('certificate and unknown failures are never retried', () async {
      for (final type in [
        DioExceptionType.badCertificate,
        DioExceptionType.unknown,
      ]) {
        create((options, __) => throw DioException(
            requestOptions: options, type: type, error: 'private-details'));
        await expectLater(
            client.get('me'),
            throwsA(isA<ApiFailure>()
                .having((e) => e.canRetry, 'retry', isFalse)
                .having((e) => e.toString(), 'redacted',
                    isNot(contains('private-details')))));
        expect(adapter.requests, hasLength(1));
      }
    });

    test('logout during read backoff prevents the second request', () async {
      final received = Completer<void>();
      create((_, __) {
        if (!received.isCompleted) received.complete();
        return jsonResponse({}, 503);
      });
      final pending = expectLater(
          client.get('me'),
          throwsA(
              isA<ApiFailure>().having((e) => e.code, 'code', 'CANCELLED')));
      await received.future;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      client.cancelSession();
      await pending;
      expect(adapter.requests, hasLength(1));
    });

    test('closed client refuses new work', () async {
      create((_, __) => jsonResponse({}));
      client.close();
      await expectLater(
          client.get('me'),
          throwsA(
              isA<ApiFailure>().having((e) => e.code, 'code', 'CANCELLED')));
      expect(adapter.requests, isEmpty);
    });

    test('account change during async token fetch cannot send old identity',
        () async {
      final token = Completer<String?>();
      create((_, __) => jsonResponse({}), token: () => token.future);
      final pending = client.get('me');
      client.cancelSession();
      token.complete('old-account-token');
      await expectLater(
          pending,
          throwsA(
              isA<ApiFailure>().having((e) => e.code, 'code', 'CANCELLED')));
      expect(adapter.requests, isEmpty);
    });

    test('logout discards a response from a pending request', () async {
      final started = Completer<void>();
      final response = Completer<ResponseBody>();
      create((_, __) {
        started.complete();
        return response.future;
      });
      final pending = client.get('me');
      final expectation = expectLater(
          pending,
          throwsA(
              isA<ApiFailure>().having((e) => e.code, 'code', 'CANCELLED')));
      await started.future;
      client.cancelSession();
      response.complete(jsonResponse({'id': 'old-user'}));
      await expectation;
    });
  });
}
