import '../../data/models/ai_provider.dart';
import '../../data/services/card_data_extractor.dart';
import '../../domain/models/card_brief.dart';
import '../../domain/models/card_data.dart';

abstract class ICardRepository {
  Future<CardData> extractCardData({
    required CardBrief brief,
    required AiProvider provider,
    required String modelId,
    required String apiKey,
  });
}

class CardRepository implements ICardRepository {
  final CardDataExtractor _extractor;
  CardRepository([CardDataExtractor? extractor]) : _extractor = extractor ?? CardDataExtractor();

  @override
  Future<CardData> extractCardData({
    required CardBrief brief,
    required AiProvider provider,
    required String modelId,
    required String apiKey,
  }) {
    return _extractor.extractCardData(brief: brief, provider: provider, modelId: modelId, apiKey: apiKey);
  }
}
