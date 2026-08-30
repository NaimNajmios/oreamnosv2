import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:injectable/injectable.dart';

import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Dio-backed API client
@lazySingleton
class ApiClient {
  ApiClient()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.addAll([
      AuthInterceptor(),
      RetryInterceptor(
        dio: _dio,
        maxRetries: 4,
        baseDelayMs: 500,
        maxDelayMs: 60000,
      ),
      ErrorMappingInterceptor(),
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  final Dio _dio;
  Dio get dio => _dio;

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.post<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.get<T>(path, queryParameters: queryParameters, options: options);
}
