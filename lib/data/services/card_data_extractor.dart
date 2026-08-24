import 'dart:convert';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/services/json_cleaner.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

class CardDataExtractor {
  Future<CardData> extractCardData({
    required String generatedText,
    required AiProvider provider,
    required String modelId,
    required String apiKey,
    required CardTemplate template,
  }) async {
    final curator = CuratorFactory.getCurator(provider);
    final jsonString = await curator.extractCardData(
      generatedText: generatedText,
      modelId: modelId,
      apiKey: apiKey,
      template: template,
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
