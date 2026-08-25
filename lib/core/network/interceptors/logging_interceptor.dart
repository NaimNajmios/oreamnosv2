import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only logging — mirrors Android `GeminiService.java:910` printf.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[DIO] → ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[DIO] ← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[DIO] ✗ ${err.response?.statusCode} ${err.requestOptions.uri} ${err.message}');
    }
    handler.next(err);
  }
}
