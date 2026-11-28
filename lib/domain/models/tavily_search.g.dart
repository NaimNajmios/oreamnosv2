// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tavily_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TavilySearchResponse _$TavilySearchResponseFromJson(
  Map<String, dynamic> json,
) => _TavilySearchResponse(
  query: json['query'] as String? ?? '',
  results:
      (json['results'] as List<dynamic>?)
          ?.map((e) => TavilySearchResult.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  answer: json['answer'] as String? ?? '',
  credits: (json['credits'] as num?)?.toInt() ?? 0,
  requestId: json['request_id'] as String?,
  responseTime: (json['response_time'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$TavilySearchResponseToJson(
  _TavilySearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'results': instance.results,
  'answer': instance.answer,
  'credits': instance.credits,
  'request_id': instance.requestId,
  'response_time': instance.responseTime,
};

_TavilySearchResult _$TavilySearchResultFromJson(Map<String, dynamic> json) =>
    _TavilySearchResult(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      content: json['content'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      publishedDate: json['published_date'] as String?,
      rawContent: json['raw_content'] as String?,
      favicon: json['favicon'] as String?,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$TavilySearchResultToJson(_TavilySearchResult instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'content': instance.content,
      'score': instance.score,
      'published_date': instance.publishedDate,
      'raw_content': instance.rawContent,
      'favicon': instance.favicon,
      'id': instance.id,
    };
