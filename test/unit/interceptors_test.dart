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
    });
  });
}
