import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Exponential backoff + jitter retry interceptor.
///
/// Parity with Android `GeminiService.java:840`:
///   MAX_RETRIES=5, INITIAL=1000ms, MAX=32000ms, multiplier 2.0
/// Flutter adaptation per Phase A spec: MAX_RETRIES=4, BASE 500ms, CAP 60s.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.dio,
    this.maxRetries = 4,
    this.baseDelayMs = 500,
    this.maxDelayMs = 60000,
    this.backoffMultiplier = 2.0,
  });

  final Dio? dio;
  final int maxRetries;
  final int baseDelayMs;
  final int maxDelayMs;
  final double backoffMultiplier;

  final _random = Random();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final retries = (extra['retryCount'] as int?) ?? 0;

    // Do not retry on auth errors — Android GeminiService.java:902 early throw
    final status = err.response?.statusCode;
    if (status == 401 || status == 403 || status == 400) {
      handler.next(err);
      return;
    }

    final isRetryableStatus =
        status == 429 || status == 503 || (status != null && status >= 500);
    final isRetryableException =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    if (!isRetryableStatus && !isRetryableException) {
      handler.next(err);
      return;
    }

    if (retries >= maxRetries) {
      handler.next(err);
      return;
    }

    // Honor Retry-After header if present (seconds)
    int? retryAfterMs;
    final retryAfterHeader = err.response?.headers.value('retry-after');
    if (retryAfterHeader != null) {
      final seconds = int.tryParse(retryAfterHeader);
      if (seconds != null) retryAfterMs = seconds * 1000;
    }

    final backoff = retryAfterMs ?? _calculateBackoff(retries);
    await Future.delayed(Duration(milliseconds: backoff));

    final opts = err.requestOptions;
    opts.extra = Map<String, dynamic>.from(opts.extra)
      ..['retryCount'] = retries + 1;
    try {
      final client =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );
      final response = await client.fetch(opts);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      } else {
        handler.next(err);
      }
    }
  }

  int _calculateBackoff(int retryCount) {
    // exponential: base * multiplier^retryCount
    var delay = (baseDelayMs * pow(backoffMultiplier, retryCount)).toInt();
    delay = delay.clamp(baseDelayMs, maxDelayMs);
    // jitter: +-15% (Android used random, verdict says jitter)
    final jitter = (_random.nextDouble() * 0.3 - 0.15) * delay;
    return (delay + jitter).round().clamp(baseDelayMs, maxDelayMs);
  }
}
