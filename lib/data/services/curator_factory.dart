import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/domain/services/content_curator.dart';
import 'package:oreamnos/data/services/curators/gemini_curator.dart';
import 'package:oreamnos/data/services/curators/openai_compatible_curator.dart';

class CuratorFactory {
  static IContentCurator getCurator(AiProvider provider, {ApiClient? apiClient}) {
    switch (provider) {
      case AiProvider.gemini:
        return GeminiCurator(apiClient: apiClient);
      case AiProvider.groq:
      case AiProvider.openRouter:
      case AiProvider.cerebras:
        return OpenAICompatibleCurator(provider.baseUrl, apiClient: apiClient);
    }
  }
}
