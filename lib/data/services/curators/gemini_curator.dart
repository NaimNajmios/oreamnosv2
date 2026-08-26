import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/domain/services/content_curator.dart';
import 'package:oreamnos/domain/services/card_prompt_manager.dart';
import 'package:oreamnos/domain/services/generation_prompt_manager.dart';
import 'package:oreamnos/domain/services/json_cleaner.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/models/curated_post.dart';

class GeminiCurator implements IContentCurator {
  GeminiCurator({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  @override
  Future<String> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required String tone,
    required String defaultHashtags,
  }) async {
    // Legacy delegates to structured then returns markdown
    final post = await generateStructuredPost(
      content: contentOrUrl,
      modelId: modelId,
      apiKey: apiKey,
      sourceUrl: null,
    );
    return post.rawMarkdown;
  }

  @override
  Future<CuratedPost> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    List<String> searchSources = const [],
  }) async {
    final resolvedSourceUrl =
        sourceUrl ?? (content is ExtractedArticle ? content.url : null);
    final systemPrompt = GenerationPromptManager.buildSystemPrompt(
      sourceUrl: resolvedSourceUrl,
      searchSources: searchSources,
    );
    final userPrompt = GenerationPromptManager.buildUserPrompt(content);

    final actualModelId = modelId.startsWith('models/')
        ? modelId
        : 'models/$modelId';
    final path =
        'https://generativelanguage.googleapis.com/v1beta/$actualModelId:generateContent';

    final response = await _client.post(
      path,
      data: {
        "system_instruction": {
          "parts": [
            {"text": systemPrompt},
          ],
        },
        "contents": [
          {
            "parts": [
              {"text": userPrompt},
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.7,
          "responseMimeType": "application/json",
        },
      },
      options: Options(extra: {'apiKey': apiKey, 'provider': 'gemini'}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API Error: ${response.statusCode} - ${response.data}',
      );
    }

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : (response.data is String
              ? jsonDecode(response.data as String) as Map<String, dynamic>
              : (response.data as Map).cast<String, dynamic>());

    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned empty response');
    }

    final parts = candidates[0]['content']?['parts'] as List<dynamic>? ?? [];
    if (parts.isEmpty) {
      throw Exception('Gemini returned empty text parts');
    }

    final rawText = parts[0]['text'] as String;
    return _parseCuratedPost(rawText, resolvedSourceUrl);
  }

  Future<CuratedPost> _parseCuratedPost(
    String rawText,
    String? sourceUrl,
  ) async {
    try {
      final jsonMap = await JsonCleaner.decodeIsolate(rawText);
      // Ensure source url/domain
      if (jsonMap['source'] is Map) {
        final sm = jsonMap['source'] as Map<String, dynamic>;
        if ((sm['url'] == null || (sm['url'] as String).isEmpty) &&
            sourceUrl != null &&
            sourceUrl.isNotEmpty) {
          sm['url'] = sourceUrl;
          sm['domain'] = Uri.tryParse(sourceUrl)?.host;
          if ((sm['label'] as String?)?.isEmpty ?? true) {
            sm['label'] = Uri.tryParse(sourceUrl)?.host ?? '';
          }
        }
      }
      return CuratedPost.fromJson(jsonMap);
    } catch (_) {
      // Fallback: treat as markdown
      SourceAttribution? src;
      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        src = SourceAttribution(
          label: Uri.tryParse(sourceUrl)?.host ?? sourceUrl,
          url: sourceUrl,
          domain: Uri.tryParse(sourceUrl)?.host,
        );
      }
      return CuratedPost.fromMarkdownFallback(rawText, source: src);
    }
  }

  @override
  Future<String> extractCardData({
    required CardBrief brief,
    required String modelId,
    required String apiKey,
    CardTemplate? template,
    bool isRefresh = false,
  }) async {
    final systemPrompt = CardPromptManager.buildSystemPrompt();
    final userPrompt = CardPromptManager.buildPrompt(
      template ?? CardTemplate.socialPost,
      brief.promptContext,
      isRefresh,
    );

    final actualModelId = modelId.startsWith('models/')
        ? modelId
        : 'models/$modelId';
    final path =
        'https://generativelanguage.googleapis.com/v1beta/$actualModelId:generateContent';

    final response = await _client.post(
      path,
      data: {
        "system_instruction": {
          "parts": [
            {"text": systemPrompt},
          ],
        },
        "contents": [
          {
            "parts": [
              {"text": userPrompt},
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.3,
          "responseMimeType": "application/json",
        },
      },
      options: Options(extra: {'apiKey': apiKey, 'provider': 'gemini'}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API Error: ${response.statusCode} - ${response.data}',
      );
    }

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : (response.data is String
              ? jsonDecode(response.data as String) as Map<String, dynamic>
              : (response.data as Map).cast<String, dynamic>());

    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned empty response');
    }

    final parts = candidates[0]['content']?['parts'] as List<dynamic>? ?? [];
    if (parts.isEmpty) {
      throw Exception('Gemini returned empty text parts');
    }

    return parts[0]['text'] as String;
  }

  @override
  Future<String> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
  }) async {
    try {
      final prompt =
          'Rewrite the following $fieldName text to be concise, grammatically correct, and suitable for a social media graphic. Return ONLY the rewritten text, with no quotes or extra formatting.\n\nText: $text';

      final actualModelId = modelId.startsWith('models/')
          ? modelId
          : 'models/$modelId';
      final path =
          'https://generativelanguage.googleapis.com/v1beta/$actualModelId:generateContent';
      final response = await _client.post(
        path,
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        },
        options: Options(extra: {'apiKey': apiKey, 'provider': 'gemini'}),
      );

      final data = response.data;
      final rewrittenText =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      return rewrittenText.trim();
    } catch (e) {
      throw Exception('Failed to rewrite field: $e');
    }
  }
}
