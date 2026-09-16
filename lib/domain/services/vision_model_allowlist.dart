import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

/// Hardcoded allow-list of vision-capable free-tier models.
///
/// Guarantees $0 by construction: the vision chain may only route to these
/// IDs. Any attempt to use a paid model (e.g. Gemini Pro) throws.
abstract final class VisionModelAllowlist {
  static const geminiFlashLite = 'gemini-2.5-flash-lite';
  static const geminiFlash = 'gemini-2.5-flash';
  static const geminiFlash20 = 'gemini-2.0-flash';
  static const groqScout = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const groqVision11b = 'meta-llama/llama-3.2-11b-vision-preview';
  static const groqVision90b = 'meta-llama/llama-3.2-90b-vision-preview';

  static const _exact = {
    geminiFlashLite,
    geminiFlash,
    geminiFlash20,
    groqScout,
    groqVision11b,
    groqVision90b,
  };

  /// Returns true when [modelId] is allowed for vision on [provider].
  /// OpenRouter `:free` suffixed models are allowed (any vision id ending
  /// in `:free`); everything else must be in [_exact].
  static bool isAllowed(AiProvider provider, String modelId) {
    final id = modelId.trim();
    if (id.isEmpty) return false;
    final lower = id.toLowerCase();
    // Block known paid families outright.
    if (lower.contains('pro') ||
        lower.contains('ultra') ||
        lower.contains('gpt-4o') && !lower.contains('mini') ||
        lower.contains('claude-opus')) {
      // Allow explicit free variants even if substring matches loosely.
      if (!lower.endsWith(':free')) return false;
    }
    if (provider == AiProvider.openRouter) {
      if (lower.endsWith(':free')) return true;
    }
    if (_exact.contains(id)) return true;
    // Gemini flash family is vision-capable and free-tier.
    if (provider == AiProvider.gemini && lower.contains('flash')) {
      return !lower.contains('pro');
    }
    // Groq llama vision/scout family.
    if (provider == AiProvider.groq &&
        (lower.contains('scout') || lower.contains('vision'))) {
      return true;
    }
    return false;
  }

  static void assertAllowed(AiProvider provider, String modelId) {
    if (!isAllowed(provider, modelId)) {
      throw UnknownFailure(
        'Vision model "$modelId" is not in the free-tier allow-list '
        'for ${provider.displayName}.',
      );
    }
  }

  /// Sensible free vision default per provider (used when user has no model
  /// selected or selected a text-only model).
  static String defaultFor(AiProvider provider) {
    return switch (provider) {
      AiProvider.gemini => geminiFlashLite,
      AiProvider.groq => groqScout,
      AiProvider.openRouter => 'meta-llama/llama-3.2-11b-vision-instruct:free',
      AiProvider.cerebras => provider.defaultModelId,
    };
  }

  /// True when the configured model should be replaced by [defaultFor]
  /// because it is text-only (e.g. Groq llama-3.3-70b-versatile).
  static bool needsVisionDefault(AiProvider provider, String? modelId) {
    if (modelId == null || modelId.trim().isEmpty) return true;
    if (provider == AiProvider.cerebras) return false;
    return !isAllowed(provider, modelId);
  }
}
