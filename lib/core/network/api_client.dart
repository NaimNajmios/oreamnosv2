import 'package:dio/dio.dart';

/// Dio-backed API client — Phase A will replace `http.post` in
/// `lib/data/services/curators/gemini_curator.dart:40` and
/// `lib/data/services/curators/openai_compatible_curator.dart:42`.
///
/// Phase 0: stub with sensible defaults; not yet used by curators.
/// Verifies `dio` dependency resolves. Interceptors (logging, retry, auth,
/// error mapping → `lib/core/error/failures.dart`) land in Phase A.
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
    // Phase A: add interceptors
    // _dio.interceptors.add(LogInterceptor(responseBody: true));
    // _dio.interceptors.add(RetryInterceptor(...));
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
