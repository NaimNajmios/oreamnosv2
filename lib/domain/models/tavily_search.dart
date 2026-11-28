import 'package:freezed_annotation/freezed_annotation.dart';

part 'tavily_search.freezed.dart';
part 'tavily_search.g.dart';

@freezed
abstract class TavilySearchResponse with _$TavilySearchResponse {
  const factory TavilySearchResponse({
    @Default('') String query,
    @Default([]) List<TavilySearchResult> results,
    @Default('') String answer,

    /// Credits consumed by this request (`include_usage: true`).
    @Default(0) int credits,
    @JsonKey(name: 'request_id') String? requestId,
    @JsonKey(name: 'response_time') @Default(0.0) double responseTime,
  }) = _TavilySearchResponse;

  factory TavilySearchResponse.fromJson(Map<String, dynamic> json) =>
      _$TavilySearchResponseFromJson(json);
}

@freezed
abstract class TavilySearchResult with _$TavilySearchResult {
  const factory TavilySearchResult({
    @Default('') String title,
    @Default('') String url,
    @Default('') String content,
    @Default(0.0) double score,
    @JsonKey(name: 'published_date') String? publishedDate,
    @JsonKey(name: 'raw_content') String? rawContent,
    String? favicon,
    String? id,
  }) = _TavilySearchResult;

  factory TavilySearchResult.fromJson(Map<String, dynamic> json) =>
      _$TavilySearchResultFromJson(json);
}

/// Request parameters for `POST /search`.
///
/// Only fields Tavily actually accepts are serialized. `country` is only valid
/// with `topic: general` (Tavily rejects it for `news`), and `max_age_hours`
/// only applies to `news`.
class SearchOptions {
  const SearchOptions({
    required this.query,
    this.topic = 'general',
    this.searchDepth = 'basic',
    this.maxResults = 4,
    this.chunksPerSource = 2,
    this.includeAnswer = false,
    this.timeRange,
    this.maxAgeHours,
    this.country,
    this.language,
    this.includeDomains = const [],
    this.excludeDomains = const [],
    this.includeUsage = true,
  });

  final String query;
  final String topic;
  final String searchDepth;
  final int maxResults;
  final int chunksPerSource;
  final bool includeAnswer;
  final String? timeRange;
  final int? maxAgeHours;
  final String? country;
  final String? language;
  final List<String> includeDomains;
  final List<String> excludeDomains;
  final bool includeUsage;

  bool get isTimeSensitive => maxAgeHours != null || timeRange == 'day';

  SearchOptions copyWith({
    String? query,
    String? topic,
    String? searchDepth,
    int? maxResults,
    int? chunksPerSource,
    bool? includeAnswer,
    String? timeRange,
    int? maxAgeHours,
    String? country,
    String? language,
    List<String>? includeDomains,
    List<String>? excludeDomains,
    bool? includeUsage,
  }) {
    return SearchOptions(
      query: query ?? this.query,
      topic: topic ?? this.topic,
      searchDepth: searchDepth ?? this.searchDepth,
      maxResults: maxResults ?? this.maxResults,
      chunksPerSource: chunksPerSource ?? this.chunksPerSource,
      includeAnswer: includeAnswer ?? this.includeAnswer,
      timeRange: timeRange ?? this.timeRange,
      maxAgeHours: maxAgeHours ?? this.maxAgeHours,
      country: country ?? this.country,
      language: language ?? this.language,
      includeDomains: includeDomains ?? this.includeDomains,
      excludeDomains: excludeDomains ?? this.excludeDomains,
      includeUsage: includeUsage ?? this.includeUsage,
    );
  }

  Map<String, dynamic> toJson() => {
    'query': query,
    'topic': topic,
    'search_depth': searchDepth,
    'max_results': maxResults,
    'chunks_per_source': chunksPerSource,
    'include_answer': includeAnswer,
    if (timeRange != null) 'time_range': timeRange,
    if (maxAgeHours != null) 'max_age_hours': maxAgeHours,
    // Tavily rejects `country` on `topic: news`; only send it where valid.
    if (country != null && topic == 'general') 'country': country,
    if (language != null) 'language': language,
    if (includeDomains.isNotEmpty) 'include_domains': includeDomains,
    if (excludeDomains.isNotEmpty) 'exclude_domains': excludeDomains,
    if (includeUsage) 'include_usage': true,
  };

  /// Cache key: query plus every parameter that can change the result set.
  String get cacheKey => [
    query.trim().toLowerCase(),
    topic,
    searchDepth,
    maxResults,
    chunksPerSource,
    includeAnswer,
    timeRange ?? '',
    maxAgeHours?.toString() ?? '',
    country ?? '',
    language ?? '',
    includeDomains.join(','),
    excludeDomains.join(','),
  ].join('|');

  @override
  String toString() =>
      'SearchOptions(query: $query, topic: $topic, depth: $searchDepth, '
      'max: $maxResults)';
}

/// Result of a Settings → Web search → Test action.
class SearchConnectionResult {
  const SearchConnectionResult({
    required this.ok,
    this.message = '',
    this.credits = 0,
  });

  const SearchConnectionResult.success({
    this.message = 'Connected',
    this.credits = 0,
  }) : ok = true;

  const SearchConnectionResult.failure(this.message) : ok = false, credits = 0;

  final bool ok;
  final String message;
  final int credits;
}
