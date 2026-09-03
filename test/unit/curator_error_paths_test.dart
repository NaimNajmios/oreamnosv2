import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/core/network/interceptors/auth_interceptor.dart';
import 'package:oreamnos/core/network/interceptors/error_interceptor.dart';
import 'package:oreamnos/core/network/interceptors/retry_interceptor.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/curators/gemini_curator.dart';
import 'package:oreamnos/data/services/curators/openai_compatible_curator.dart';
import 'package:oreamnos/domain/models/card_brief.dart';

class _StatusAdapter implements HttpClientAdapter {
  final int status;
  final Map<String, dynamic> data;
  _StatusAdapter(this.status, this.data);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(data)),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _fastApiClient(int status, Map<String, dynamic> data) {
  final apiClient = ApiClient();
  apiClient.dio.httpClientAdapter = _StatusAdapter(status, data);
  // Fast retry for tests (production uses 4x500ms->60s).
  apiClient.dio.interceptors.clear();
  apiClient.dio.interceptors.addAll([
    AuthInterceptor(),
    RetryInterceptor(
      dio: apiClient.dio,
      maxRetries: 1,
      baseDelayMs: 10,
      maxDelayMs: 20,
    ),
    ErrorMappingInterceptor(),
  ]);
  return apiClient;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curator error paths', () {
    test('Gemini 429 surfaces RateLimitFailure', () async {
      final apiClient = _fastApiClient(429, {
        'error': {'message': 'quota exceeded'},
      });
      final curator = GeminiCurator(apiClient: apiClient);

      await expectLater(
        () => curator.generateStructuredPost(
          content: 'JDT won.',
          modelId: 'gemini-2.0-flash',
          apiKey: 'fake',
        ),
        throwsA(isA<RateLimitFailure>()),
      );
    });

    test('OpenAI-compat 429 surfaces RateLimitFailure', () async {
      final apiClient = _fastApiClient(429, {
        'error': {'message': 'rate limit'},
      });
      final curator = OpenAICompatibleCurator(
        'https://api.groq.com/openai/v1',
        apiClient: apiClient,
      );

      await expectLater(
        () => curator.generateStructuredPost(
          content: 'Arsenal won.',
          modelId: 'llama-3.3-70b-versatile',
          apiKey: 'fake',
        ),
        throwsA(isA<RateLimitFailure>()),
      );
    });

    test(
      'Gemini extractCardData passes raw text through (extractor parses later)',
      () async {
        final apiClient = _fastApiClient(200, {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'this is not json at all {{{'},
                ],
              },
            },
          ],
        });
        final curator = GeminiCurator(apiClient: apiClient);

        final raw = await curator.extractCardData(
          brief: const CardBrief(
            headline: 'h',
            subtext: 'b',
            provider: AiProvider.gemini,
            modelId: 'gemini-2.0-flash',
          ),
          modelId: 'gemini-2.0-flash',
          apiKey: 'fake',
        );
        expect(raw, 'this is not json at all {{{');
      },
    );
  });
}
