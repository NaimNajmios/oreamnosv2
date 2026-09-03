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

    // Raw API bodies are truncated: a full dump must never reach the UI
    // (it overflowed the model dialog). Full bodies stay in debug logs.
    final short = _short(body);

    Failure failure;
    if (status == 429) {
      final provider = err.requestOptions.extra['provider'] as String?;
      failure = RateLimitFailure(
        'Rate limit: $status $short',
        retryDelayMs:
            _parseGeminiRetryDelay(err.response?.data) ??
            _parseRetryAfterMs(err.response),
        providerName: provider,
      );
    } else if (status == 400) {
      failure = _mapBadRequest(err, body, short);
    } else if (status == 401 || status == 403) {
      failure = AuthFailure(
        '${_providerLabel(err)} rejected the API key (HTTP $status). Check it in Settings → API Key. ($short)',
      );
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      failure = NetworkFailure('Network: ${err.message}');
    } else if (status != null && status >= 500) {
      failure = NetworkFailure('Server: $status $short');
    } else if (body.toLowerCase().contains('parse') ||
        body.toLowerCase().contains('json')) {
      failure = ParseFailure('Parse: $short');
    } else {
      failure = UnknownFailure(body.isEmpty ? err.message ?? 'Unknown' : short);
    }

    // Attach failure to extra for upstream handling (e.g., RateLimit dialog)
    err.requestOptions.extra['failure'] = failure;
    handler.next(err);
  }

  /// Collapse whitespace and cap length so raw API dumps never fill the UI.
  static String _short(String s, [int max = 220]) {
    final flat = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= max) return flat;
    return '${flat.substring(0, max)}…';
  }

  static String _providerLabel(DioException err) {
    return switch (err.requestOptions.extra['provider']) {
      'gemini' => 'Gemini',
      'openai' => 'The AI provider',
      final String other => other,
      _ => 'The AI provider',
    };
  }

  /// Friendly mapping for HTTP 400 (most often a rejected API key on the
  /// models endpoint, or a request-format rejection).
  static Failure _mapBadRequest(DioException err, String body, String short) {
    final lower = body.toLowerCase();
    if (lower.contains('api key') ||
        lower.contains('api_key') ||
        lower.contains('key not valid') ||
        lower.contains('unauthorized') ||
        lower.contains('permission denied') ||
        lower.contains('consumer')) {
      return AuthFailure(
        '${_providerLabel(err)} rejected the API key (HTTP 400). Check it in Settings → API Key. ($short)',
      );
    }
    if (lower.contains('response_schema') || lower.contains('responseschema')) {
      return UnknownFailure(
        'Gemini rejected the request format (HTTP 400). Try again or switch provider. ($short)',
      );
    }
    return UnknownFailure('Bad request (HTTP 400). $short');
  }

  /// Parses Gemini `error.details[]` entries shaped like
  /// `{@type: .../RetryInfo, retryDelay: "34s"}` into milliseconds.
  /// Mirrors Android `GeminiService.parseRetryDelay`.
  static int? _parseGeminiRetryDelay(dynamic data) {
    try {
      final Map<String, dynamic> root;
      if (data is Map<String, dynamic>) {
        root = data;
      } else {
        return null;
      }
      final error = root['error'];
      if (error is! Map<String, dynamic>) return null;
      final details = error['details'];
      if (details is! List) return null;
      for (final d in details) {
        if (d is! Map<String, dynamic>) continue;
        final raw = d['retryDelay'] as String?;
        if (raw == null) continue;
        final digits = RegExp(r'[0-9]+').allMatches(raw).map((m) => m.group(0));
        if (digits.isEmpty) continue;
        final value = int.tryParse(digits.join());
        if (value == null) continue;
        // "34s" → seconds; guard against millis-style values by magnitude.
        return raw.trim().toLowerCase().endsWith('ms') ? value : value * 1000;
      }
    } catch (_) {}
    return null;
  }

  /// Parses the `Retry-After` response header (seconds, with optional
  /// millis-style values) into milliseconds.
  static int? _parseRetryAfterMs(Response? response) {
    try {
      final raw = response?.headers.value('retry-after');
      if (raw == null) return null;
      final seconds = int.tryParse(raw.trim());
      if (seconds == null) return null;
      return seconds * 1000;
    } catch (_) {
      return null;
    }
  }
}
