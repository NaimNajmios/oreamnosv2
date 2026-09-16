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
  static const gemini31FlashLite = 'gemini-3.1-flash-lite';
  static const groqScout = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const groqMaverick = 'meta-llama/llama-4-maverick-17b-128e-instruct';
  static const openRouterFreeRouter = 'openrouter/free';

  /// Pinned vision-capable free-tier IDs (Sept 2026 refresh).
  ///
  /// Rationale: Gemini 3.5/3.6/3.8 Flash are real but target the new
  /// Interactions API / lack a generateContent free tier and return HTTP 400
  /// on the legacy endpoint — so they are deliberately NOT allowed here and
  /// fall back to 2.5-flash-lite. Groq `llama-3.2-*-vision-preview` IDs are
  /// decommissioned (HTTP 404) and were removed.
  static const _exact = {
    geminiFlashLite,
    geminiFlash,
    geminiFlash20,
    gemini31FlashLite,
    groqScout,
    groqMaverick,
    openRouterFreeRouter,
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
      if (lower == openRouterFreeRouter) return true;
    }
    if (_exact.contains(id)) return true;
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
  /// selected or selected a text-only/retired model).
  ///
  /// OpenRouter uses the `openrouter/free` router, which auto-selects a free
  /// model matching the request's features (image understanding) instead of
  /// a hardcoded `:free` ID that rotates away (e.g. the retired
  /// `llama-3.2-11b-vision-instruct:free` which now 404s with
  /// "No endpoints found").
  static String defaultFor(AiProvider provider) {
    return switch (provider) {
      AiProvider.gemini => geminiFlashLite,
      AiProvider.groq => groqScout,
      AiProvider.openRouter => openRouterFreeRouter,
      AiProvider.cerebras => provider.defaultModelId,
    };
  }

  /// Ordered candidate vision models to try per provider before hopping to
  /// the next provider. First entry is [defaultFor]; extras are fallbacks
  /// when the first 404s (retired ID) without burning the next provider.
  static List<String> candidatesFor(AiProvider provider) {
    return switch (provider) {
      AiProvider.gemini => const [geminiFlashLite, geminiFlash, geminiFlash20],
      AiProvider.groq => const [groqScout, groqMaverick],
      AiProvider.openRouter => const [openRouterFreeRouter],
      AiProvider.cerebras => const [],
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
