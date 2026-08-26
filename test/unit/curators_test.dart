import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/curators/gemini_curator.dart';
import 'package:oreamnos/data/services/curators/openai_compatible_curator.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  final Map<String, dynamic> responseData;

  _FakeHttpAdapter({required this.responseData});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = utf8.encode(jsonEncode(responseData));
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiCurator', () {
    test(
      'generateStructuredPost parses structured Gemini API response',
      () async {
        final mockJsonText = jsonEncode({
          "title": "Historic Victory for JDT",
          "body": "JDT secured a decisive 3-0 victory in the semi-final.",
          "hashtags": ["JDT", "LuaskanKuasamu", "ACL"],
        });

        final apiClient = ApiClient();
        apiClient.dio.httpClientAdapter = _FakeHttpAdapter(
          responseData: {
            "candidates": [
              {
                "content": {
                  "parts": [
                    {"text": "```json\n$mockJsonText\n```"},
                  ],
                },
              },
            ],
          },
        );

        final curator = GeminiCurator(apiClient: apiClient);

        final result = await curator.generateStructuredPost(
          content: "JDT won 3-0 against Selangor.",
          modelId: "gemini-1.5-flash",
          apiKey: "fake_gemini_key",
        );

        final post = result;
        expect(post.title, "Historic Victory for JDT");
        expect(post.bodyMarkdown, contains("decisive 3-0 victory"));
        expect(post.hashtags, contains("JDT"));
      },
    );
  });

  group('OpenAICompatibleCurator', () {
    test(
      'generateStructuredPost parses structured OpenAI-style response',
      () async {
        final mockJsonText = jsonEncode({
          "title": "Arsenal Edge Past City",
          "body": "A late goal sealed the win.",
          "hashtags": ["Arsenal", "ManCity", "PremierLeague"],
        });

        final apiClient = ApiClient();
        apiClient.dio.httpClientAdapter = _FakeHttpAdapter(
          responseData: {
            "choices": [
              {
                "message": {"content": mockJsonText},
              },
            ],
          },
        );

        final curator = OpenAICompatibleCurator(
          "https://api.groq.com/openai/v1",
          apiClient: apiClient,
        );

        final result = await curator.generateStructuredPost(
          content: "Arsenal beat Manchester City 1-0.",
          modelId: "llama-3.3-70b-versatile",
          apiKey: "fake_groq_key",
        );

        final post = result;
        expect(post.title, "Arsenal Edge Past City");
        expect(post.bodyMarkdown, contains("late goal"));
        expect(post.hashtags, contains("Arsenal"));
      },
    );
  });
}
