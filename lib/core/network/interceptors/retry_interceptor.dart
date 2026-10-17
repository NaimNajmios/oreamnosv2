import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Exponential backoff + jitter retry interceptor.
///
/// Parity with Android `GeminiService.java:840`:
///   MAX_RETRIES=5, INITIAL=1000ms, MAX=32000ms, multiplier 2.0
/// Flutter adaptation per Phase A spec: MAX_RETRIES=4, BASE 500ms, CAP 60s.
///
/// 429 policy: at most [maxRetriesOn429] retries, and only when the
/// provider supplies a `Retry-After` within [retry429MaxWaitMs]. A long or
/// unknown quota window (typical Gemini free-tier RPM limit) propagates
/// immediately so the ViewModel fallback chain can switch provider instead
/// of burning the quota window with doomed requests.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.dio,
    this.maxRetries = 4,
    this.baseDelayMs = 500,
    this.maxDelayMs = 60000,
    this.backoffMultiplier = 2.0,
    this.maxRetriesOn429 = 1,
    this.retry429MaxWaitMs = 10000,
  });

  final Dio? dio;
  final int maxRetries;
  final int baseDelayMs;
  final int maxDelayMs;
  final double backoffMultiplier;

  /// Max retries for HTTP 429.
  final int maxRetriesOn429;

  /// Only honor a 429 retry when the provider-provided wait is at most
  /// this many milliseconds.
  final int retry429MaxWaitMs;

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

    // Honor Retry-After header if present (seconds)
    int? retryAfterMs;
    final retryAfterHeader = err.response?.headers.value('retry-after');
    if (retryAfterHeader != null) {
      final seconds = int.tryParse(retryAfterHeader);
      if (seconds != null) retryAfterMs = seconds * 1000;
    }

    final is429 = status == 429;
    final isRetryableStatus =
        status == 503 || (status != null && status >= 500) || is429;
    final isRetryableException =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    if (!isRetryableStatus && !isRetryableException) {
      handler.next(err);
      return;
    }

    int delayMs;
    if (is429) {
      if (retries >= maxRetriesOn429 ||
          retryAfterMs == null ||
          retryAfterMs > retry429MaxWaitMs) {
        handler.next(err);
        return;
      }
      delayMs = retryAfterMs;
    } else {
      if (retries >= maxRetries) {
        handler.next(err);
        return;
      }
      delayMs = retryAfterMs ?? _calculateBackoff(retries);
    }

    await Future.delayed(Duration(milliseconds: delayMs));

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
