import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/token_usage_side_channel.dart';
import 'package:oreamnos/domain/services/content_curator.dart';
import 'package:oreamnos/domain/services/card_prompt_manager.dart';
import 'package:oreamnos/domain/services/generation_prompt_manager.dart';
import 'package:oreamnos/domain/services/json_cleaner.dart';
import 'package:oreamnos/domain/services/response_cleanup.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/core/error/failures.dart';

class OpenAICompatibleCurator implements IContentCurator {
  OpenAICompatibleCurator(this.baseUrl, {ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();

  final String baseUrl;
  final ApiClient _client;

  /// OpenRouter requires ranking headers (Android parity).
  bool get isOpenRouter => baseUrl.contains('openrouter');

  Map<String, String> get _providerHeaders => {
    'Content-Type': 'application/json',
    if (isOpenRouter) ...{
      'HTTP-Referer': 'https://github.com/NaimNajmios/Oreamnos',
      'X-Title': 'Oreamnos',
    },
  };

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
    bool keepStructure = false,
    bool isFanModeEnabled = false,
    String fanClubName = '',
    String length = 'medium',
    String? siteName,
    String? authorDisplayName,
    String? candidateOutlet,
    bool isTwitter = false,
  }) async {
    final resolvedSourceUrl =
        sourceUrl ?? (content is ExtractedArticle ? content.url : null);
    final resolvedSiteName =
        siteName ?? (content is ExtractedArticle ? content.siteName : null);
    final systemPrompt = GenerationPromptManager.buildSystemPrompt(
      sourceUrl: resolvedSourceUrl,
      searchSources: searchSources,
      keepStructure: keepStructure,
      isFanModeEnabled: isFanModeEnabled,
      fanClubName: fanClubName,
      length: length,
      sourceText: GenerationPromptManager.plainTextOf(content),
      siteName: resolvedSiteName,
      authorDisplayName: authorDisplayName,
      candidateOutlet: candidateOutlet,
      isTwitter: isTwitter,
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
          "max_tokens": 2048,
          "response_format": {
            "type": "json_schema",
            "json_schema": {
              "name": "curated_post",
              "strict": true,
              "schema": GenerationPromptManager.jsonSchema(
                keepStructure: keepStructure,
              ),
            },
          },
        },
        options: Options(
          extra: {'apiKey': apiKey, 'provider': 'openai'},
          headers: _providerHeaders,
          // Android OpenAI-path parity: connect 30s / read 60s.
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
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

    // Side-channel: capture real token usage (OpenAI usage) — skeleton stays minimal
    try {
      if (getIt.isRegistered<TokenUsageSideChannel>()) {
        getIt<TokenUsageSideChannel>().storeOpenAi(data, baseUrl);
      }
    } catch (_) {}

    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('API returned empty response');
    }

    final message = choices[0]['message'];
    final rawText = message['content'] as String;
    return _parseCuratedPost(
      rawText,
      resolvedSourceUrl,
      siteName: resolvedSiteName,
      authorDisplayName: authorDisplayName,
      candidateOutlet: candidateOutlet,
      isTwitter: isTwitter,
    );
  }

  Future<CuratedPost> _parseCuratedPost(
    String rawText,
    String? sourceUrl, {
    String? siteName,
    String? authorDisplayName,
    String? candidateOutlet,
    bool isTwitter = false,
  }) async {
    try {
      final jsonMap = await JsonCleaner.decodeIsolate(rawText);
      if (jsonMap['source'] is Map) {
        final sm = jsonMap['source'] as Map<String, dynamic>;
        if ((sm['url'] == null ||
                (sm['url'] is String && (sm['url'] as String).isEmpty)) &&
            sourceUrl != null &&
            sourceUrl.isNotEmpty) {
          sm['url'] = sourceUrl;
          sm['domain'] = Uri.tryParse(sourceUrl)?.host;
        }
        final currentLabel = (sm['label'] as String?) ?? '';
        if (currentLabel.trim().isEmpty) {
          final seed = _seedLabel(
            siteName: siteName,
            authorDisplayName: authorDisplayName,
            candidateOutlet: candidateOutlet,
            isTwitter: isTwitter,
          );
          if (seed != null && seed.isNotEmpty) sm['label'] = seed;
        }
      }
      return CuratedPost.fromJson(jsonMap);
    } catch (_) {
      SourceAttribution? src;
      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        final seed = _seedLabel(
          siteName: siteName,
          authorDisplayName: authorDisplayName,
          candidateOutlet: candidateOutlet,
          isTwitter: isTwitter,
        );
        src = SourceAttribution(
          label: seed ?? '',
          url: sourceUrl,
          domain: Uri.tryParse(sourceUrl)?.host,
        );
      }
      return CuratedPost.fromMarkdownFallback(
        ResponseCleanup.cleanUpResponseWithMarkdown(rawText),
        source: src,
      );
    }
  }

  String? _seedLabel({
    String? siteName,
    String? authorDisplayName,
    String? candidateOutlet,
    bool isTwitter = false,
  }) {
    final outlet = (candidateOutlet ?? '').trim();
    final site = (siteName ?? '').trim();
    final author = (authorDisplayName ?? '').trim();
    if (isTwitter) {
      if (outlet.isNotEmpty && author.isNotEmpty) return '$outlet via $author';
      return null;
    }
    if (site.isNotEmpty) return site;
    if (outlet.isNotEmpty) return outlet;
    return null;
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
        options: Options(
          extra: {'apiKey': apiKey, 'provider': 'openai'},
          headers: _providerHeaders,
        ),
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
  Future<CuratedPost> refinePost({
    required CuratedPost original,
    required List<String> refinements,
    required String modelId,
    required String apiKey,
    bool includeSource = true,
    bool keepStructure = false,
  }) async {
    final systemPrompt = GenerationPromptManager.buildSystemPrompt(
      sourceUrl: original.source.url,
      keepStructure: keepStructure,
      sourceText: original.rawMarkdown,
    );
    final userPrompt =
        '${GenerationPromptManager.buildRefinementPrompt(originalPost: original.rawMarkdown, refinements: refinements, includeSource: includeSource)}\n\nReturn ONLY the JSON object per the schema.';

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
          "max_tokens": 2048,
          "response_format": {
            "type": "json_schema",
            "json_schema": {
              "name": "curated_post",
              "strict": true,
              "schema": GenerationPromptManager.jsonSchema(
                keepStructure: keepStructure,
              ),
            },
          },
        },
        options: Options(
          extra: {'apiKey': apiKey, 'provider': 'openai'},
          headers: _providerHeaders,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
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

    try {
      if (getIt.isRegistered<TokenUsageSideChannel>()) {
        getIt<TokenUsageSideChannel>().storeOpenAi(data, baseUrl);
      }
    } catch (_) {}

    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('API returned empty response');
    }
    final message = choices[0]['message'];
    return _parseCuratedPost(message['content'] as String, original.source.url);
  }

  @override
  Future<String> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
  }) async {
    try {
      final safeText = text
          .replaceAll('<<<FIELD>>>', '[FIELD]')
          .replaceAll('<<<END>>>', '[END]');
      final response = await _client.post(
        '$baseUrl/chat/completions',
        options: Options(
          extra: {'apiKey': apiKey, 'provider': 'openai'},
          headers: _providerHeaders,
        ),
        data: {
          "model": modelId,
          "messages": [
            {
              "role": "system",
              "content": "You are a concise Bahasa Malaysia copy editor for sports. Keep football terms in English in sentence case (e.g. \"clean sheet\", not \"CLEAN SHEET\"). Return ONLY the rewritten text, no quotes or extra formatting.",
            },
            {
              "role": "user",
              "content":
                  'Rewrite the $fieldName below into concise, grammatically correct Bahasa Malaysia for a social graphic. No emoji, no quotes.\n\n<<<FIELD>>>\n$safeText\n<<<END>>>',
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
