import 'package:injectable/injectable.dart';

/// Side-channel for real token counts extracted from API responses.
/// Keeps skeleton minimal — no changes to CuratedPost, just stores last usage
/// for GenerateViewModel to consume via getIt.
@lazySingleton
class TokenUsageSideChannel {
  int? lastPromptTokens;
  int? lastCompletionTokens;
  int? lastTotalTokens;
  String? lastProvider;

  void storeGemini(Map<String, dynamic> data, String provider) {
    final meta = data['usageMetadata'] as Map<String, dynamic>?;
    if (meta == null) return;
    lastPromptTokens = (meta['promptTokenCount'] as num?)?.toInt();
    lastCompletionTokens = (meta['candidatesTokenCount'] as num?)?.toInt();
    lastTotalTokens = (meta['totalTokenCount'] as num?)?.toInt();
    lastProvider = provider;
  }

  void storeOpenAi(Map<String, dynamic> data, String provider) {
    final usage = data['usage'] as Map<String, dynamic>?;
    if (usage == null) return;
    lastPromptTokens = (usage['prompt_tokens'] as num?)?.toInt();
    lastCompletionTokens = (usage['completion_tokens'] as num?)?.toInt();
    lastTotalTokens = (usage['total_tokens'] as num?)?.toInt();
    lastProvider = provider;
  }

  int? consumeTotal() {
    final v = lastTotalTokens;
    // Clear after consume to avoid stale reuse
    clear();
    return v;
  }

  void clear() {
    lastPromptTokens = null;
    lastCompletionTokens = null;
    lastTotalTokens = null;
    lastProvider = null;
  }
}
