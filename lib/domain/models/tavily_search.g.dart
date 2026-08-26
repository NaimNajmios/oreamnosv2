// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tavily_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TavilySearchResponse _$TavilySearchResponseFromJson(
  Map<String, dynamic> json,
) => _TavilySearchResponse(
  query: json['query'] as String,
  results: (json['results'] as List<dynamic>)
      .map((e) => TavilySearchResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  answer: json['answer'] as String? ?? '',
);

Map<String, dynamic> _$TavilySearchResponseToJson(
  _TavilySearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'results': instance.results,
  'answer': instance.answer,
};

_TavilySearchResult _$TavilySearchResultFromJson(Map<String, dynamic> json) =>
    _TavilySearchResult(
      title: json['title'] as String,
      url: json['url'] as String,
      content: json['content'] as String,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$TavilySearchResultToJson(_TavilySearchResult instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'content': instance.content,
      'score': instance.score,
    };
