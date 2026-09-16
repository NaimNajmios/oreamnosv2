import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/curator_factory.dart';
import 'package:oreamnos/data/services/free_tier_guard.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/provider_api_service.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/services/vision_model_allowlist.dart';

/// $0 vision chain: Gemini Flash-Lite -> Groq scout/maverick ->
/// OpenRouter free router. Cerebras is text-only and skipped.
///
/// Every hop is free-tier; quota exhaustion surfaces as [RateLimitFailure]
/// (never a bill) and the caller falls through to on-device ML Kit.
@lazySingleton
class VisionCuratorChain {
  VisionCuratorChain(this._prefs, this._guard, [ProviderApiService? discovery])
    : _discovery = discovery;

  final PreferencesService _prefs;
  final FreeTierGuard _guard;
  final ProviderApiService? _discovery;

  ProviderApiService? get _disco =>
      _discovery ??
      (getIt.isRegistered<ProviderApiService>()
          ? getIt<ProviderApiService>()
          : null);

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
      final modelIds = await _modelIdsFor(provider, apiKey);
      for (final modelId in modelIds) {
        try {
          final curator = CuratorFactory.getCurator(provider);
          final post = await curator.generateStructuredPost(
            content: content,
            modelId: modelId,
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
          if (_isModelNotFound(e)) {
            // Retired model ID (HTTP 404 / "No endpoints found"): retry the
            // same provider with the next pinned candidate before hopping.
            _logInfo(
              'Vision model "$modelId" unavailable on '
              '${provider.displayName}, trying next candidate',
            );
            continue;
          }
          // Rate-limit / network / server / auth / payment: hop providers
          // (different key), so break the candidate loop.
          break;
        }
      }
    }
    throw lastFailure ??
        const UnknownFailure(
          'No vision provider available (missing API keys).',
        );
  }

  /// Ordered model IDs to try for [provider]: the user's stored selection
  /// when still allow-listed, else pinned candidates; OpenRouter prepends
  /// live-discovered `:free` vision IDs so rotation self-heals.
  Future<List<String>> _modelIdsFor(AiProvider provider, String apiKey) async {
    if (provider == AiProvider.openRouter) {
      final live = await _discoverOpenRouterVision(apiKey);
      final ids = <String>[...live];
      final stored = _prefs.getSelectedModel(provider);
      if (stored != null &&
          stored.trim().isNotEmpty &&
          VisionModelAllowlist.isAllowed(provider, stored) &&
          !ids.contains(stored)) {
        ids.add(stored);
      }
      for (final c in VisionModelAllowlist.candidatesFor(provider)) {
        if (!ids.contains(c)) ids.add(c);
      }
      return ids.take(3).toList();
    }
    final stored = _prefs.getSelectedModel(provider);
    if (stored != null &&
        stored.trim().isNotEmpty &&
        VisionModelAllowlist.isAllowed(provider, stored)) {
      return [stored];
    }
    if (stored != null && stored.trim().isNotEmpty) {
      _logInfo(
        'Vision model "$stored" not in free-tier allow-list for '
        '${provider.displayName}, using ${VisionModelAllowlist.defaultFor(provider)}',
      );
    }
    return VisionModelAllowlist.candidatesFor(provider).take(2).toList();
  }

  Future<List<String>> _discoverOpenRouterVision(String apiKey) async {
    try {
      final disco = _disco;
      if (disco == null) return const [];
      final live = await disco
          .fetchFreeVisionModels(apiKey)
          .timeout(const Duration(seconds: 10));
      return live.take(2).toList();
    } catch (_) {
      return const [];
    }
  }

  static bool _isModelNotFound(Failure e) {
    final m = e.message.toLowerCase();
    return m.contains('404') ||
        m.contains('no endpoints found') ||
        m.contains('model_not_found') ||
        m.contains('model not found') ||
        m.contains('does not exist');
  }

  void _logInfo(String message) {
    try {
      if (getIt.isRegistered<LogService>()) {
        getIt<LogService>().info(message);
      }
    } catch (_) {}
  }
}
