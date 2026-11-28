import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../config/constants.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/tavily_search.dart';
import '../../domain/repositories/search_repository.dart';
import '../services/preferences_service.dart';

@LazySingleton(as: ISearchRepository)
class TavilySearchRepository implements ISearchRepository {
  TavilySearchRepository(this._apiClient, this._prefs);

  final ApiClient _apiClient;
  final PreferencesService _prefs;
  static const _baseUrl = AppConstants.tavilyBaseUrl;

  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();

  Future<String> _getApiKey({String? override}) async {
    final key = (override ?? await _prefs.getTavilyApiKey())?.trim() ?? '';
    if (key.isEmpty) {
      throw const AuthFailure(
        'Tavily API key is not configured. Add it in Settings → Web search.',
      );
    }
    return key;
  }

  @override
  Future<bool> isConfigured() async {
    final key = await _prefs.getTavilyApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  @override
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  }) async {
    final result = await search(
      SearchOptions(
        query: query,
        maxResults: maxResults,
        includeAnswer: includeAnswer,
        topic: 'news',
        searchDepth: 'advanced',
      ),
    );
    return result.fold((data) => data, (failure) => throw failure);
  }

  @override
  Future<Result<TavilySearchResponse>> search(
    SearchOptions options, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = options.cacheKey;
    final cached = _readCache(cacheKey);
    if (cached != null) return ResultSuccess(cached);

    try {
      final key = await _getApiKey();
      final response = await _apiClient.post(
        '$_baseUrl/search',
        data: options.toJson(),
        cancelToken: cancelToken,
        options: Options(
          headers: {'Authorization': 'Bearer $key'},
          extra: {'provider': 'tavily', 'search': true},
          receiveTimeout: AppConstants.tavilySearchTimeout,
        ),
      );
      final parsed = _parseSearch(response.data);
      if (!options.isTimeSensitive) _writeCache(cacheKey, parsed);
      return ResultSuccess(parsed);
    } catch (e) {
      return ResultError(mapSearchException(e));
    }
  }

  TavilySearchResponse _parseSearch(dynamic data) {
    if (data is! Map) {
      throw const ParseFailure('Tavily returned a non-JSON search response.');
    }
    final map = Map<String, dynamic>.from(data);
    final usage = map['usage'];
    final credits = usage is Map
        ? (usage['credits'] as num?)?.toInt() ?? 0
        : (map['credits'] as num?)?.toInt() ?? 0;
    return TavilySearchResponse.fromJson(map).copyWith(
      credits: credits,
      requestId: map['request_id'] as String?,
      responseTime: (map['response_time'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<String> extractFromUrl(String url) async {
    final result = await extract(url);
    return result.fold((data) => data, (failure) => throw failure);
  }

  @override
  Future<Result<String>> extract(
    String url, {
    CancelToken? cancelToken,
    String? query,
  }) async {
    try {
      final key = await _getApiKey();
      final response = await _apiClient.post(
        '$_baseUrl/extract',
        data: {
          'urls': [url],
          'extract_depth': 'basic',
          'format': 'markdown',
          'include_usage': true,
          if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {'Authorization': 'Bearer $key'},
          extra: {'provider': 'tavily', 'extract': true},
          receiveTimeout: AppConstants.tavilyExtractTimeout,
        ),
      );

      final data = response.data;
      if (data is! Map) {
        throw const ParseFailure(
          'Tavily returned a non-JSON extract response.',
        );
      }
      final results = data['results'];
      if (results is List && results.isNotEmpty) {
        final first = results.first;
        if (first is Map) {
          final raw = first['raw_content'];
          if (raw is String && raw.trim().isNotEmpty) return ResultSuccess(raw);
        }
      }

      // HTTP 200 can still mean every URL failed; surface the real reason.
      final failed = data['failed_results'];
      if (failed is List && failed.isNotEmpty) {
        final first = failed.first;
        final reason = first is Map
            ? (first['error']?.toString() ?? 'unknown error')
            : 'unknown error';
        return ResultError(
          ParseFailure('Tavily could not extract this page: $reason'),
        );
      }
      return const ResultError(
        ParseFailure('Tavily returned no readable content for this page.'),
      );
    } catch (e) {
      return ResultError(mapSearchException(e));
    }
  }

  @override
  Future<SearchConnectionResult> testConnection({String? apiKey}) async {
    try {
      final key = await _getApiKey(override: apiKey);
      final response = await _apiClient.post(
        '$_baseUrl/search',
        data: const SearchOptions(
          query: 'football',
          maxResults: 1,
          includeAnswer: false,
        ).toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $key'},
          extra: {'provider': 'tavily', 'search': true},
          receiveTimeout: AppConstants.tavilySearchTimeout,
        ),
      );
      final parsed = _parseSearch(response.data);
      return SearchConnectionResult.success(
        message: 'Connected · ${parsed.results.length} result(s)',
        credits: parsed.credits,
      );
    } catch (e) {
      final failure = mapSearchException(e);
      return SearchConnectionResult.failure(failure.message);
    }
  }

  TavilySearchResponse? _readCache(String key) {
    final entry = _cache.remove(key);
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) return null;
    // Re-insert to keep LRU order (most recently used last).
    _cache[key] = entry;
    return entry.response;
  }

  void _writeCache(String key, TavilySearchResponse response) {
    _cache.remove(key);
    _cache[key] = _CacheEntry(
      response: response,
      expiresAt: DateTime.now().add(AppConstants.tavilyCacheTtl),
    );
    while (_cache.length > AppConstants.tavilyCacheMaxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}

class _CacheEntry {
  const _CacheEntry({required this.response, required this.expiresAt});

  final TavilySearchResponse response;
  final DateTime expiresAt;
}
