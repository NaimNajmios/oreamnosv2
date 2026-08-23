import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_data.g.dart';

@JsonSerializable()
class CardData extends Equatable {
  final String title;
  final String subtitle;
  final String? quote;
  final List<String> keyPoints;

  const CardData({
    required this.title,
    required this.subtitle,
    this.quote,
    this.keyPoints = const [],
  });

  factory CardData.fromJson(Map<String, dynamic> json) =>
      _$CardDataFromJson(json);

  Map<String, dynamic> toJson() => _$CardDataToJson(this);

  @override
  List<Object?> get props => [title, subtitle, quote, keyPoints];
}

