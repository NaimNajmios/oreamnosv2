import 'package:dio/dio.dart';

import '../../error/failures.dart';

/// Maps DioException + HTTP status to sealed Failure hierarchy.
/// Phase A: centralizes `Exception('Gemini API Error: ${status}')` patterns
/// from `gemini_curator.dart:64` and `openai_compatible_curator.dart:60`.
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final body = err.response?.data?.toString() ?? err.message ?? '';

    Failure failure;
    if (status == 429) {
      failure = RateLimitFailure('Rate limit: $status $body');
    } else if (status == 401 || status == 403) {
      failure = AuthFailure('Auth failed: $status $body');
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      failure = NetworkFailure('Network: ${err.message}');
    } else if (status != null && status >= 500) {
      failure = NetworkFailure('Server: $status $body');
    } else if (body.toLowerCase().contains('parse') ||
        body.toLowerCase().contains('json')) {
      failure = ParseFailure('Parse: $body');
    } else {
      failure = UnknownFailure(body.isEmpty ? err.message ?? 'Unknown' : body);
    }

    // Attach failure to extra for upstream handling (e.g., RateLimit dialog)
    err.requestOptions.extra['failure'] = failure;
    handler.next(err);
  }
}
