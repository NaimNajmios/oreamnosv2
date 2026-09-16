import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/data/services/free_tier_guard.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/services/vision_model_allowlist.dart';

/// $0 vision chain: Gemini Flash-Lite -> Groq scout-vision ->
/// OpenRouter :free vision. Cerebras is text-only and skipped.
///
/// Every hop is free-tier; quota exhaustion surfaces as [RateLimitFailure]
/// (never a bill) and the caller falls through to on-device ML Kit.
@lazySingleton
class VisionCuratorChain {
  VisionCuratorChain(this._prefs, this._guard);

  final PreferencesService _prefs;
  final FreeTierGuard _guard;

  static const List<AiProvider> chain = [
    AiProvider.gemini,
    AiProvider.groq,
    AiProvider.openRouter,
  ];

  /// Runs structured vision extraction over [imageBytes].
  ///
  /// [content] is the accompanying text hint (may be empty for pure
  /// screenshots). Returns the curated post from the first provider that
  /// succeeds. Throws the last [Failure] when all hops fail.
  Future<CuratedPost> extractStructured({
    required dynamic content,
    required Uint8List imageBytes,
    required String imageMimeType,
    String? sourceUrl,
    bool keepStructure = false,
  }) async {
    Failure? lastFailure;
    for (final provider in chain) {
      if (_guard.shouldSkip(provider)) continue;
      final apiKey = await _prefs.getApiKey(provider);
      if (apiKey == null || apiKey.isEmpty) continue;
      var modelId = _prefs.getSelectedModel(provider);
      if (VisionModelAllowlist.needsVisionDefault(provider, modelId)) {
        modelId = VisionModelAllowlist.defaultFor(provider);
      }
      final resolvedModel = modelId;
      if (resolvedModel == null) continue;
      try {
        VisionModelAllowlist.assertAllowed(provider, resolvedModel);
      } on Failure catch (e) {
        lastFailure = e;
        continue;
      }
      try {
        final curator = CuratorFactory.getCurator(provider);
        final post = await curator.generateStructuredPost(
          content: content,
          modelId: resolvedModel,
          apiKey: apiKey,
          sourceUrl: sourceUrl,
          keepStructure: keepStructure,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
        );
        await _guard.record(provider);
        return post;
      } on Failure catch (e) {
        lastFailure = e;
        // Rate-limit / network / server errors hop to the next provider.
        if (e is RateLimitFailure ||
            e is NetworkFailure ||
            e is ServerFailure ||
            e is UnknownFailure) {
          continue;
        }
        // Auth / payment failures are terminal for this chain hop set:
        // still try the next provider (different key), so continue.
        continue;
      }
    }
    throw lastFailure ??
        const UnknownFailure(
          'No vision provider available (missing API keys).',
        );
  }
}
