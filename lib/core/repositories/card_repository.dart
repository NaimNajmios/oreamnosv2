import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../core/di/injection.dart';
import '../../core/error/failures.dart';
import '../../data/models/ai_provider.dart';
import '../../data/services/card_data_extractor.dart';
import '../../domain/models/card_brief.dart';
import '../../domain/models/card_data.dart';
import '../../domain/models/card_template.dart';

abstract class ICardRepository {
  Future<Result<CardData>> extractCardData({
    required CardBrief brief,
    required AiProvider provider,
    required String modelId,
    required String apiKey,
    CardTemplate? template,
    bool isRefresh = false,
  });
}

@LazySingleton(as: ICardRepository)
class CardRepository implements ICardRepository {
  final CardDataExtractor _extractor;
  CardRepository(this._extractor);

  Failure _mapError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('429') ||
        msg.contains('rate limit') ||
        msg.contains('quota') ||
        msg.contains('resource_exhausted')) {
      return RateLimitFailure(e.toString());
    }
    if (msg.contains('parse') || msg.contains('json')) {
      return ParseFailure(e.toString());
    }
    if (msg.contains('network') || msg.contains('timeout')) {
      return NetworkFailure(e.toString());
    }
    return UnknownFailure(e.toString());
  }

  @override
  Future<Result<CardData>> extractCardData({
    required CardBrief brief,
    required AiProvider provider,
    required String modelId,
    required String apiKey,
    CardTemplate? template,
    bool isRefresh = false,
  }) async {
    try {
      final res = await _extractor.extractCardData(
        brief: brief,
        provider: provider,
        modelId: modelId,
        apiKey: apiKey,
        template: template,
        isRefresh: isRefresh,
      );
      return ResultSuccess(res);
    } catch (e) {
      return ResultError(_mapError(e));
    }
  }
}

final cardRepositoryProvider = Provider<ICardRepository>(
  (ref) => getIt<ICardRepository>(),
);
