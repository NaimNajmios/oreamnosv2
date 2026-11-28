import 'dart:async';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../config/constants.dart';
import '../../core/network/api_client.dart';
import '../../data/models/ai_provider.dart';
import '../../domain/models/query_plan_suggestion.dart';
import '../../domain/services/json_cleaner.dart';
import '../../domain/services/football_search_lexicon.dart';
import '../../domain/services/query_planner_ai.dart';
import 'preferences_service.dart';
import 'query_planner_quota_guard.dart';

/// Optional, one-shot query planner pinned to Groq.
///
/// This is deliberately NOT a provider hop: the user's selected generation
/// provider is untouched, and no other provider is ever tried here. Any
/// failure — missing key, local cap, 429, timeout, model-not-found, bad JSON —
/// returns null so [EnrichContextUseCase] uses its heuristic planner.
@LazySingleton(as: QueryPlannerAi)
class GroqQueryPlannerService extends QueryPlannerAi {
  GroqQueryPlannerService(this._apiClient, this._prefs, this._quota);

  final ApiClient _apiClient;
  final PreferencesService _prefs;
  final QueryPlannerQuotaGuard _quota;

  static const _systemPrompt =
      'You extract football search hints. Return ONLY a JSON object with '
      'keys "entities" (1-6 player or club names copied exactly from the '
      'text) and "queries" (1-2 short English web search queries about the '
      'same story). Never include template labels such as TYPE, DATE or POST '
      'CONTENT, and never include weekday or month words. Do not answer the '
      'question, do not add facts, do not use markdown.';

  @override
  Future<QueryPlanSuggestion?> plan({
    required String text,
    String? pageTitle,
    CancelToken? cancelToken,
  }) async {
    if (_quota.shouldSkip) return null;
    final key = (await _prefs.getApiKey(AiProvider.groq))?.trim() ?? '';
    if (key.isEmpty) return null;

    final input = _shorten(
      [
        (pageTitle ?? '').trim(),
        text.trim(),
      ].where((s) => s.isNotEmpty).join('\n'),
    );
    if (input.isEmpty) return null;

    await _quota.record();
    try {
      final response = await _apiClient
          .post(
            '${AppConstants.groqBaseUrl}/chat/completions',
            data: {
              'model': AppConstants.groqPlannerModelId,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': 'TEXT (truncated):\n$input'},
              ],
              'response_format': {'type': 'json_object'},
              'temperature': 0,
              'max_tokens': AppConstants.groqPlannerMaxOutputTokens,
            },
            cancelToken: cancelToken,
            options: Options(
              headers: {'Authorization': 'Bearer $key'},
              extra: {
                'provider': 'groq',
                'searchPlanner': true,
                // A 429 means "skip the optional step", never wait+retry.
                'noRetry': true,
              },
              receiveTimeout: AppConstants.groqPlannerTimeout,
              sendTimeout: AppConstants.groqPlannerTimeout,
            ),
          )
          .timeout(AppConstants.groqPlannerTimeout);

      final content = _contentOf(response.data);
      if (content == null || content.isEmpty) return null;
      final json = JsonCleaner.decode(content);
      final entities = _strings(json['entities'])
          .map(_validEntity)
          .whereType<String>()
          .toList();
      final queries = _strings(json['queries'])
          .map((q) => _trimQuery(q))
          .where((q) => q.isNotEmpty)
          .toList();
      if (queries.isEmpty) return null;
      return QueryPlanSuggestion(
        entities: entities.take(6).toList(growable: false),
        queries: queries.take(2).toList(growable: false),
      );
    } catch (_) {
      // Includes 429 (no retry), 400 model-not-found, timeouts and bad JSON.
      return null;
    }
  }

  String _shorten(String text) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= AppConstants.groqPlannerMaxInputChars) return flat;
    final cut = flat.substring(0, AppConstants.groqPlannerMaxInputChars);
    final lastSpace = cut.lastIndexOf(' ');
    return (lastSpace > AppConstants.groqPlannerMaxInputChars * 0.6
            ? cut.substring(0, lastSpace)
            : cut)
        .trim();
  }

  String? _contentOf(dynamic data) {
    if (data is! Map) return null;
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    return content is String ? content : null;
  }

  List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  String? _validEntity(String raw) {
    final value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.length < 3 || value.length > 60) return null;
    if (value == value.toUpperCase()) return null;
    final words = value
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^a-z]'), ''))
        .toList();
    if (words.any(
      (word) =>
          FootballSearchLexicon.dateTokens.contains(word) ||
          FootballSearchLexicon.templateLabels.contains(word),
    )) {
      return null;
    }
    return value;
  }

  String _trimQuery(String raw) {
    var value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value == value.toUpperCase()) return '';
    final words = value.split(RegExp(r'\s+')).where((word) {
      final lower = word.toLowerCase();
      return !FootballSearchLexicon.dateTokens.contains(lower) &&
          !FootballSearchLexicon.templateLabels.contains(lower);
    }).toList();
    value = words.join(' ');
    if (value.length > AppConstants.tavilyMaxQueryChars) {
      value = value.substring(0, AppConstants.tavilyMaxQueryChars).trim();
    }
    return value;
  }
}
