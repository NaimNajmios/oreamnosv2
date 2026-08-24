import 'dart:convert';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/services/json_cleaner.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

class CardDataExtractor {
  Future<CardData> extractCardData({
    required CardBrief brief,
    required AiProvider provider,
    required String modelId,
    required String apiKey,
  }) async {
    final curator = CuratorFactory.getCurator(provider);
    final jsonString = await curator.extractCardData(
      brief: brief,
      modelId: modelId,
      apiKey: apiKey,
    );

    final cleanedJson = JsonCleaner.clean(jsonString);

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson);
      return CardData.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to parse CardData JSON: $e\nRaw: $cleanedJson');
    }
  }
}
