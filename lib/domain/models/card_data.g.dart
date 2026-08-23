// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardData _$CardDataFromJson(Map<String, dynamic> json) => CardData(
  title: json['title'] as String,
  subtitle: json['subtitle'] as String,
  quote: json['quote'] as String?,
  keyPoints:
      (json['keyPoints'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$CardDataToJson(CardData instance) => <String, dynamic>{
  'title': instance.title,
  'subtitle': instance.subtitle,
  'quote': instance.quote,
  'keyPoints': instance.keyPoints,
};
