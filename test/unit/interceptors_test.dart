import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/network/interceptors/auth_interceptor.dart';
import 'package:oreamnos/core/network/interceptors/error_interceptor.dart';
import 'package:oreamnos/core/network/interceptors/retry_interceptor.dart';
import 'package:oreamnos/core/error/failures.dart';

class _FakeErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {
    // swallow — we only care about extra['failure'] set by interceptor
  }
}

class _CapturingErrorHandler extends ErrorInterceptorHandler {
  DioException? nextErr;
  Response? resolvedResponse;
  @override
  void next(DioException err) {
    nextErr = err;
  }

  @override
  void resolve(Response response) {
    resolvedResponse = response;
  }
}

/// Adapter that records calls; returns the configured status.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);
  final int statusCode;
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString('{"ok":true}', statusCode);
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter that throws if the interceptor attempts a network call — used to
/// prove no doomed retry happens for long/unknown 429 windows.
class _NeverAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) {
    fail('RetryInterceptor must not fetch for this case');
  }

  @override
  void close({bool force = false}) {}
}

DioException _statusError(
  int status, {
  int retryCount = 0,
  Map<String, List<String>> headers = const {},
}) {
  final options = RequestOptions(
    path: '/test',
    extra: {'provider': 'gemini', if (retryCount > 0) 'retryCount': retryCount},
  );
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: status,
      data: {'error': 'rate limited'},
      headers: Headers.fromMap(headers),
    ),
  );
}

Dio _neverDio() {
  final dio = Dio();
  dio.httpClientAdapter = _NeverAdapter();
  return dio;
}

class _FakeRequestHandler extends RequestInterceptorHandler {
  @override
  void next(RequestOptions options) {}
}

void main() {
  group('AuthInterceptor', () {
    test('adds Bearer for non-gemini', () async {
      final interceptor = AuthInterceptor();
      final options = RequestOptions(
        path: '/test',
        extra: {'apiKey': 'sk-123', 'provider': 'groq'},
      );
      final handler = _FakeRequestHandler();
      interceptor.onRequest(options, handler);
      expect(options.headers['Authorization'], 'Bearer sk-123');
    });
    test('adds ?key for gemini', () async {
      final interceptor = AuthInterceptor();
      final options = RequestOptions(
        path: '/test',
        extra: {'apiKey': 'key123', 'provider': 'gemini'},
      );
      interceptor.onRequest(options, _FakeRequestHandler());
      expect(options.queryParameters['key'], 'key123');
    });
  });

  group('ErrorMappingInterceptor', () {
    test('maps 429 to RateLimitFailure', () {
      final interceptor = ErrorMappingInterceptor();
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 429,
          data: 'rate limit',
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = _FakeErrorHandler();
      interceptor.onError(dioEx, handler);
      final failure = dioEx.requestOptions.extra['failure'];
      expect(failure, isA<RateLimitFailure>());
    });
    test('maps 402 to PaymentRequiredFailure', () {
      final interceptor = ErrorMappingInterceptor();
      final dioEx = DioException(
        requestOptions: RequestOptions(
          path: '/',
          extra: {'provider': 'openrouter'},
        ),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 402,
          data: 'Payment Required: insufficient credits',
        ),
        type: DioExceptionType.badResponse,
      );
      interceptor.onError(dioEx, _FakeErrorHandler());
      final failure = dioEx.requestOptions.extra['failure'];
      expect(failure, isA<PaymentRequiredFailure>());
      expect(
        (failure as PaymentRequiredFailure).message,
        contains('Credits exhausted'),
      );
      expect(failure.providerName, 'openrouter');
    });
    test('maps 401 to AuthFailure', () {
      final interceptor = ErrorMappingInterceptor();
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 401,
          data: 'unauth',
        ),
        type: DioExceptionType.badResponse,
      );
      interceptor.onError(dioEx, _FakeErrorHandler());
      expect(dioEx.requestOptions.extra['failure'], isA<AuthFailure>());
    });

    DioException badRequest(Object? data, {String provider = 'gemini'}) {
      return DioException(
        requestOptions: RequestOptions(
          path: '/',
          extra: {'provider': provider},
        ),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 400,
          data: data,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    test('maps 400 invalid-key body to friendly AuthFailure', () {
      final interceptor = ErrorMappingInterceptor();
      final dioEx = badRequest({
        'error': {
          'code': 400,
          'message': 'API key not valid. Please pass a valid API key.',
          'status': 'INVALID_ARGUMENT',
        },
      });
      interceptor.onError(dioEx, _FakeErrorHandler());
      final failure = dioEx.requestOptions.extra['failure'];
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).message, contains('Settings → API Key'));
      expect(failure.message, isNot(contains('DioException')));
    });

    test('maps 400 schema rejection without raw dump', () {
      final interceptor = ErrorMappingInterceptor();
      final dioEx = badRequest(
        '{error: {code: 400, message: Invalid JSON payload received. '
        'Unknown name "additionalProperties" at '
        "'generation_config.response_schema': Cannot find field.}}",
      );
      interceptor.onError(dioEx, _FakeErrorHandler());
      final failure = dioEx.requestOptions.extra['failure'];
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, contains('request format'));
    });

    test('truncates long 400 bodies', () {
      final interceptor = ErrorMappingInterceptor();
      final dioEx = badRequest('x' * 2000);
      interceptor.onError(dioEx, _FakeErrorHandler());
      final failure = dioEx.requestOptions.extra['failure'] as UnknownFailure;
      expect(failure.message.length, lessThan(300));
      expect(failure.message, contains('…'));
    });
  });

  group('RetryInterceptor', () {
    test('config', () {
      final r = RetryInterceptor(
        maxRetries: 4,
        baseDelayMs: 500,
        maxDelayMs: 60000,
      );
      expect(r.maxRetries, 4);
      expect(r.baseDelayMs, 500);
      expect(r.maxRetriesOn429, 1);
      expect(r.retry429MaxWaitMs, 10000);
    });

    test(
      '429 with long Retry-After propagates immediately (no doomed retry)',
      () async {
        final interceptor = RetryInterceptor(dio: _neverDio());
        final dioEx = _statusError(
          429,
          headers: {
            'retry-after': ['34'],
          },
        );
        final handler = _CapturingErrorHandler();
        await interceptor.onError(dioEx, handler);
        expect(handler.nextErr, isNotNull);
        expect(handler.resolvedResponse, isNull);
        // retryCount unchanged — no retry consumed
        expect(dioEx.requestOptions.extra['retryCount'], isNull);
      },
    );

    test('429 without Retry-After propagates immediately', () async {
      final interceptor = RetryInterceptor(dio: _neverDio());
      final dioEx = _statusError(429);
      final handler = _CapturingErrorHandler();
      await interceptor.onError(dioEx, handler);
      expect(handler.nextErr, isNotNull);
      expect(handler.resolvedResponse, isNull);
    });

    test('second 429 propagates even with short Retry-After', () async {
      final interceptor = RetryInterceptor(dio: _neverDio());
      final dioEx = _statusError(
        429,
        retryCount: 1,
        headers: {
          'retry-after': ['1'],
        },
      );
      final handler = _CapturingErrorHandler();
      await interceptor.onError(dioEx, handler);
      expect(handler.nextErr, isNotNull);
    });

    test(
      '429 with short Retry-After retries exactly once via injected client',
      () async {
        final adapter = _StubAdapter(200);
        final dio = Dio(
          BaseOptions(
            connectTimeout: Duration(seconds: 2),
            receiveTimeout: Duration(seconds: 2),
          ),
        );
        dio.httpClientAdapter = adapter;
        final interceptor = RetryInterceptor(dio: dio);
        final dioEx = _statusError(
          429,
          headers: {
            'retry-after': ['1'],
          },
        );
        final handler = _CapturingErrorHandler();
        await interceptor.onError(dioEx, handler);
        expect(adapter.calls, 1);
        expect(handler.resolvedResponse, isNotNull);
        expect(handler.resolvedResponse!.statusCode, 200);
        expect(dioEx.requestOptions.extra['retryCount'], 1);
      },
    );

    test('5xx keeps the exponential retry path', () async {
      // First attempt: 500 → one honoring retry (Retry-After none → backoff)
      final adapter = _StubAdapter(200);
      final dio = Dio(
        BaseOptions(
          connectTimeout: Duration(seconds: 2),
          receiveTimeout: Duration(seconds: 2),
        ),
      );
      dio.httpClientAdapter = adapter;
      final interceptor = RetryInterceptor(
        dio: dio,
        baseDelayMs: 10,
        maxDelayMs: 20,
      );
      final dioEx = _statusError(500);
      final handler = _CapturingErrorHandler();
      await interceptor.onError(dioEx, handler);
      expect(adapter.calls, 1);
      expect(handler.resolvedResponse, isNotNull);
      expect(dioEx.requestOptions.extra['retryCount'], 1);
    });
  });
}
