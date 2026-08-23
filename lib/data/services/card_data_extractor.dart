import 'dart:convert';
import 'package:oreamnos/domain/models/card_data.dart';
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

    // Clean up potential markdown formatting in response (e.g., ```json ... ```)
    final cleanedJson = _cleanJsonString(jsonString);

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson);
      return CardData.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to parse CardData JSON: $e\nRaw: $cleanedJson');
    }
  }

  String _cleanJsonString(String input) {
    var text = input.trim();
    if (text.startsWith('```json')) {
      text = text.replaceFirst('```json', '');
    } else if (text.startsWith('```')) {
      text = text.replaceFirst('```', '');
    }
    
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    
    return text.trim();
  }
}
