import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Dio-backed API client — replaces `http.post` in
/// `lib/data/services/curators/gemini_curator.dart:40` and
/// `lib/data/services/curators/openai_compatible_curator.dart:42`.
///
/// Android parity: connect 30s / read 60s `GeminiService.java:930`,
/// retry 4× base 500ms cap 60s + jitter (vs Android 5× 1000ms cap 32s).
class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.addAll([
      if (kDebugMode) LoggingInterceptor(),
      AuthInterceptor(),
      ErrorMappingInterceptor(),
      RetryInterceptor(dio: _dio, maxRetries: 4, baseDelayMs: 500, maxDelayMs: 60000),
    ]);
  }

  final Dio _dio;
  Dio get dio => _dio;

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);
}
