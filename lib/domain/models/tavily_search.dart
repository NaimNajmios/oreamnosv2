import 'package:freezed_annotation/freezed_annotation.dart';

part 'tavily_search.freezed.dart';
part 'tavily_search.g.dart';

@freezed
abstract class TavilySearchResponse with _$TavilySearchResponse {
  const factory TavilySearchResponse({
    required String query,
    required List<TavilySearchResult> results,
    @Default('') String answer,
  }) = _TavilySearchResponse;

  factory TavilySearchResponse.fromJson(Map<String, dynamic> json) =>
      _$TavilySearchResponseFromJson(json);
}

@freezed
abstract class TavilySearchResult with _$TavilySearchResult {
  const factory TavilySearchResult({
    required String title,
    required String url,
    required String content,
    @Default(0.0) double score,
  }) = _TavilySearchResult;

  factory TavilySearchResult.fromJson(Map<String, dynamic> json) =>
      _$TavilySearchResultFromJson(json);
}
