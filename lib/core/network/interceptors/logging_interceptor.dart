import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only logging — mirrors Android `GeminiService.java:910` printf.
///
/// API keys are redacted: Gemini passes `?key=` in the URL and OpenAI-style
/// providers pass `Authorization: Bearer`, both of which must never appear
/// in logcat (a leaked key was observed in a pasted debug log).
class LoggingInterceptor extends Interceptor {
  static String redact(Object? uri) {
    if (uri == null) return '';
    var s = uri.toString();
    // Gemini ?key= / &key= query param.
    s = s.replaceAllMapped(
      RegExp(r'([?&]key=)[^&\s]+'),
      (m) => '${m.group(1)}[REDACTED]',
    );
    // Any Bearer token that slipped into a printable URI.
    s = s.replaceAllMapped(
      RegExp(r'Bearer\s+[A-Za-z0-9._\-~+/=]+'),
      (_) => 'Bearer [REDACTED]',
    );
    return s;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[DIO] → ${options.method} ${redact(options.uri)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[DIO] ← ${response.statusCode} ${redact(response.requestOptions.uri)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      // err.message can echo URIs; redact those too.
      debugPrint(
        '[DIO] ✗ ${err.response?.statusCode} ${redact(err.requestOptions.uri)} ${redact(err.message)}',
      );
    }
    handler.next(err);
  }
}
