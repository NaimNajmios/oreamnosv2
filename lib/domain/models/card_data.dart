import 'package:equatable/equatable.dart';

class CardData extends Equatable {
  final Map<String, dynamic> data;

  const CardData({
    required this.data,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    // If it's a nested structure, we just keep the whole json
    return CardData(data: json);
  }

  Map<String, dynamic> toJson() => data;

  @override
  List<Object?> get props => [data];

  // Helper getters for common fields
  String get title => data['title'] ?? data['headline'] ?? data['playerName'] ?? data['teamName'] ?? data['leagueName'] ?? data['awardName'] ?? data['dateLabel'] ?? data['handle'] ?? data['competition'] ?? data['player1Name'] ?? 'Generated Card';
  String get subtitle => data['subtitle'] ?? data['subtext'] ?? data['club'] ?? data['action'] ?? data['matchTime'] ?? data['matchContext'] ?? data['seasonYear'] ?? '';
}

