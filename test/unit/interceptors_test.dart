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
    });
  });
}
