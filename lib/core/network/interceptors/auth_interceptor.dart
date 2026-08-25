import 'package:dio/dio.dart';

/// Injects auth headers/query params per provider.
///
/// Gemini: `?key=API_KEY` query (or `x-goog-api-key` header) — `gemini_curator.dart:38`
/// OpenAI-compatible: `Authorization: Bearer API_KEY` — `openai_compatible_curator.dart:46`
class AuthInterceptor extends Interceptor {
  // No-op by default — per-request Options.extra['apiKey'] and extra['provider'] drive injection.
  // Keeping as separate interceptor for testability and future HuggingFace token support.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final apiKey = options.extra['apiKey'] as String?;
    final provider = options.extra['provider'] as String?;

    if (apiKey != null && apiKey.isNotEmpty) {
      if (provider == 'gemini') {
        // Gemini uses ?key= query param — ensure it's present
        options.queryParameters['key'] = apiKey;
      } else {
        // Groq/OpenRouter/Cerebras use Bearer
        options.headers['Authorization'] = 'Bearer $apiKey';
      }
    }
    handler.next(options);
  }
}
