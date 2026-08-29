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
import 'package:oreamnos/core/error/failures.dart';

class OpenAICompatibleCurator implements IContentCurator {
  OpenAICompatibleCurator(this.baseUrl, {ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();

  final String baseUrl;
  final ApiClient _client;

  @override
  Future<String> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required String tone,
    required String defaultHashtags,
  }) async {
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

    final path = '$baseUrl/chat/completions';

    Response response;
    try {
      response = await _client.post(
        path,
        data: {
          "model": modelId,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userPrompt},
          ],
          "temperature": 0.7,
          "response_format": {"type": "json_object"},
        },
        options: Options(extra: {'apiKey': apiKey, 'provider': 'openai'}),
      );
    } on DioException catch (e) {
      if (e.requestOptions.extra.containsKey('failure')) {
        throw e.requestOptions.extra['failure'] as Failure;
      }
      rethrow;
    }

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode} - ${response.data}');
    }

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : (response.data is String
              ? jsonDecode(response.data as String) as Map<String, dynamic>
              : (response.data as Map).cast<String, dynamic>());

    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('API returned empty response');
    }

    final message = choices[0]['message'];
    final rawText = message['content'] as String;
    return _parseCuratedPost(rawText, resolvedSourceUrl);
  }

  Future<CuratedPost> _parseCuratedPost(
    String rawText,
    String? sourceUrl,
  ) async {
    try {
      final jsonMap = await JsonCleaner.decodeIsolate(rawText);
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

    final path = '$baseUrl/chat/completions';

    Response response;
    try {
      response = await _client.post(
        path,
        data: {
          "model": modelId,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userPrompt},
          ],
          "temperature": 0.3,
          "response_format": {"type": "json_object"},
        },
        options: Options(extra: {'apiKey': apiKey, 'provider': 'openai'}),
      );
    } on DioException catch (e) {
      if (e.requestOptions.extra.containsKey('failure')) {
        throw e.requestOptions.extra['failure'] as Failure;
      }
      rethrow;
    }

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode} - ${response.data}');
    }

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : (response.data is String
              ? jsonDecode(response.data as String) as Map<String, dynamic>
              : (response.data as Map).cast<String, dynamic>());

    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('API returned empty response');
    }

    final message = choices[0]['message'];
    return message['content'] as String;
  }

  @override
  Future<String> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
  }) async {
    try {
      final safeText = text.replaceAll('<<<FIELD>>>', '[FIELD]').replaceAll('<<<END>>>', '[END]');
      final response = await _client.post(
        '$baseUrl/chat/completions',
        options: Options(extra: {'apiKey': apiKey, 'provider': 'openai'}),
        data: {
          "model": modelId,
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a concise Bahasa Malaysia copy editor for sports. Keep football terms in English in sentence case (e.g. \"clean sheet\", not \"CLEAN SHEET\"). Return ONLY the rewritten text, no quotes or extra formatting.",
            },
            {
              "role": "user",
              "content": 'Rewrite the $fieldName below into concise, grammatically correct Bahasa Malaysia for a social graphic. No emoji, no quotes.\n\n<<<FIELD>>>\n$safeText\n<<<END>>>',
            },
          ],
          "temperature": 0.5,
        },
      );

      final data = response.data;
      final rewrittenText = data['choices'][0]['message']['content'] as String;
      return rewrittenText.trim();
    } on DioException catch (e) {
      if (e.requestOptions.extra.containsKey('failure')) {
        throw e.requestOptions.extra['failure'] as Failure;
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to rewrite field: $e');
    }
  }
}
