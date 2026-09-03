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

class GeminiCurator implements IContentCurator {
  GeminiCurator({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// POSTs a generateContent payload. If Gemini hard-rejects the
  /// `responseSchema` (HTTP 400 naming `response_schema`), retries once
  /// without it — the schema stays in the prompt text and `JsonCleaner`
  /// still parses the output.
  Future<Response> _postGenerate({
    required String path,
    required Map<String, dynamic> data,
    required String apiKey,
  }) async {
    try {
      return await _client.post(
        path,
        data: data,
        options: Options(extra: {'apiKey': apiKey, 'provider': 'gemini'}),
      );
    } on DioException catch (e) {
      final config = data['generationConfig'];
      if (config is Map<String, dynamic> &&
          config.containsKey('responseSchema') &&
          _isSchemaRejection(e)) {
        final retryConfig = Map<String, dynamic>.from(config)
          ..remove('responseSchema');
        final retryData = Map<String, dynamic>.from(data)
          ..['generationConfig'] = retryConfig;
        return await _client.post(
          path,
          data: retryData,
          options: Options(extra: {'apiKey': apiKey, 'provider': 'gemini'}),
        );
      }
      rethrow;
    }
  }

  static bool _isSchemaRejection(DioException e) {
    if (e.response?.statusCode != 400) return false;
    final body = e.response?.data?.toString().toLowerCase() ?? '';
    return body.contains('response_schema') || body.contains('responseschema');
  }

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

    final actualModelId = modelId.startsWith('models/')
        ? modelId
        : 'models/$modelId';
    final path =
        'https://generativelanguage.googleapis.com/v1beta/$actualModelId:generateContent';

    Response response;
    try {
      response = await _postGenerate(
        path: path,
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
            "responseSchema": GenerationPromptManager.geminiResponseSchema(
              keepStructure: keepStructure,
            ),
          },
        },
        apiKey: apiKey,
      );
    } on DioException catch (e) {
      if (e.requestOptions.extra.containsKey('failure')) {
        throw e.requestOptions.extra['failure'] as Failure;
      }
      rethrow;
    }

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

    // Side-channel: capture real token usage (Gemini usageMetadata) — keep skeleton minimal
    try {
      if (getIt.isRegistered<TokenUsageSideChannel>()) {
        getIt<TokenUsageSideChannel>().storeGemini(data, 'gemini');
      }
    } catch (_) {}

    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned empty response');
    }

    final parts = candidates[0]['content']?['parts'] as List<dynamic>? ?? [];
    if (parts.isEmpty) {
      throw Exception('Gemini returned empty text parts');
    }

    final rawText = parts[0]['text'] as String;
    return _parseCuratedPost(
      rawText,
      resolvedSourceUrl,
      siteName: resolvedSiteName,
      authorDisplayName: authorDisplayName,
      candidateOutlet: candidateOutlet,
      isTwitter: isTwitter,
    );
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

    final actualModelId = modelId.startsWith('models/')
        ? modelId
        : 'models/$modelId';
    final path =
        'https://generativelanguage.googleapis.com/v1beta/$actualModelId:generateContent';

    Response response;
    try {
      response = await _postGenerate(
        path: path,
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
            "responseSchema": GenerationPromptManager.geminiResponseSchema(
              keepStructure: keepStructure,
            ),
          },
        },
        apiKey: apiKey,
      );
    } on DioException catch (e) {
      if (e.requestOptions.extra.containsKey('failure')) {
        throw e.requestOptions.extra['failure'] as Failure;
      }
      rethrow;
    }

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

    try {
      if (getIt.isRegistered<TokenUsageSideChannel>()) {
        getIt<TokenUsageSideChannel>().storeGemini(data, 'gemini');
      }
    } catch (_) {}

    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned empty response');
    }
    final parts = candidates[0]['content']?['parts'] as List<dynamic>? ?? [];
    if (parts.isEmpty) {
      throw Exception('Gemini returned empty text parts');
    }
    return _parseCuratedPost(parts[0]['text'] as String, original.source.url);
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
      // Backfill source.url for internal use only. NEVER derive
      // source.label from the URL/domain — leave it "" when the LLM
      // provides no content-based outlet (CuratedPost sanitizer enforces).
      if (jsonMap['source'] is Map) {
        final sm = jsonMap['source'] as Map<String, dynamic>;
        if ((sm['url'] == null ||
                (sm['url'] is String && (sm['url'] as String).isEmpty)) &&
            sourceUrl != null &&
            sourceUrl.isNotEmpty) {
          sm['url'] = sourceUrl;
          sm['domain'] = Uri.tryParse(sourceUrl)?.host;
        }
        // Seed label from content-based candidates only (never host).
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
      // Fallback: clean markdown chatter then treat as markdown.
      // Label stays "" (never host); url preserved for internal use.
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

  /// Content-based label seed only. Returns null when no outlet is known
  /// so the label stays blank instead of falling back to URL/host.
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
      // No confirmed outlet in content → blank (never handle/URL alone).
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

    final actualModelId = modelId.startsWith('models/')
        ? modelId
        : 'models/$modelId';
    final path =
        'https://generativelanguage.googleapis.com/v1beta/$actualModelId:generateContent';

    Response response;
    try {
      response = await _client.post(
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
            "topP": 1,
            "maxOutputTokens": 1024,
            "responseMimeType": "application/json",
          },
        },
        options: Options(extra: {'apiKey': apiKey, 'provider': 'gemini'}),
      );
    } on DioException catch (e) {
      if (e.requestOptions.extra.containsKey('failure')) {
        throw e.requestOptions.extra['failure'] as Failure;
      }
      rethrow;
    }

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
      final safeText = text
          .replaceAll('<<<FIELD>>>', '[FIELD]')
          .replaceAll('<<<END>>>', '[END]');
      final prompt =
          'You are a sports copy editor for Malaysian Malay (Bahasa Malaysia) audience.\n'
          'Rewrite the $fieldName below to be concise, grammatically correct Bahasa Malaysia, suitable for a social media graphic.\n'
          'Keep football terms in English in sentence case (e.g. "clean sheet", "hat-trick", not "CLEAN SHEET"). No emoji, no quotes, no extra formatting.\n'
          'Return ONLY the rewritten text.\n\n'
          '<<<FIELD>>>\n$safeText\n<<<END>>>';
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
              {
                "text": 'You are a concise Bahasa Malaysia copy editor. Output only the rewritten text, no quotes or formatting.',
              },
            ],
          },
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {"temperature": 0.5, "maxOutputTokens": 256},
        },
        options: Options(extra: {'apiKey': apiKey, 'provider': 'gemini'}),
      );

      final data = response.data;
      final rewrittenText =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
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
