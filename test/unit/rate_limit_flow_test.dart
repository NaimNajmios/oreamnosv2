import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/repositories/content_repository.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Script-driven mock: each call consumes the next queued [Result]; when the
/// script is empty an unconditional success is returned.
class _MockContentRepository implements IContentRepository {
  final List<Result<CuratedPost>> _script = [];
  int callCount = 0;
  AiProvider? lastProvider;

  void queue(Result<CuratedPost> result) => _script.add(result);

  Result<CuratedPost> _next() {
    if (_script.isNotEmpty) return _script.removeAt(0);
    return const ResultSuccess(
      CuratedPost(
        title: 'Test Headline',
        bodyMarkdown: 'Test Body Markdown',
        hashtags: ['TestHashtag'],
        source: SourceAttribution(label: 'source'),
        rawMarkdown: 'Test Raw Markdown',
      ),
    );
  }

  @override
  Future<Result<CuratedPost>> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    required AiProvider provider,
    List<String> searchSources = const [],
    bool keepStructure = false,
    bool isFanModeEnabled = false,
    String fanClubName = '',
    String length = 'medium',
    String? siteName,
    String? authorDisplayName,
    String? candidateOutlet,
    bool isTwitter = false,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    callCount++;
    lastProvider = provider;
    return _next();
  }

  @override
  Future<Result<CuratedPost>> refinePost({
    required CuratedPost original,
    required List<String> refinements,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    bool includeSource = true,
    bool keepStructure = false,
  }) async {
    callCount++;
    lastProvider = provider;
    return _next();
  }

  @override
  Future<Result<String>> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    required String tone,
    required String defaultHashtags,
  }) async {
    callCount++;
    lastProvider = provider;
    final r = _next();
    return r.fold(
      (data) => ResultSuccess<String>(data.rawMarkdown),
      (failure) => ResultError<String>(failure),
    );
  }

  @override
  Future<Result<String>> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
  }) async {
    return const ResultSuccess('Rewritten');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RateLimit & Fallback Chain Tests', () {
    test('AiProvider circular fallback chain', () {
      expect(AiProvider.gemini.nextFallback, AiProvider.groq);
      expect(AiProvider.groq.nextFallback, AiProvider.openRouter);
      expect(AiProvider.openRouter.nextFallback, AiProvider.cerebras);
      expect(AiProvider.cerebras.nextFallback, AiProvider.gemini);
    });

    test(
      '429 silently auto-falls back to the next keyed provider and succeeds',
      () async {
        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        const storage = FlutterSecureStorage();
        final prefService = PreferencesService(
          prefs: prefs,
          secureStorage: storage,
        );
        await prefService.setApiKey(AiProvider.gemini, 'fake-gemini-key');
        await prefService.setSelectedModel(
          AiProvider.gemini,
          'gemini-1.5-flash',
        );
        await prefService.setApiKey(AiProvider.groq, 'fake-groq-key');
        // Intentionally no model for Groq — auto-fallback must persist the
        // provider default model.

        final mockRepo = _MockContentRepository();
        mockRepo.queue(
          const ResultError(
            RateLimitFailure('429 Resource Exhausted', retryDelayMs: 34000),
          ),
        );
        // Script empty afterwards → success for the fallback attempt.

        await getIt.reset();
        await configureDependencies();
        getIt.allowReassignment = true;
        getIt.registerLazySingleton<PreferencesService>(() => prefService);
        getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
        getIt.registerLazySingleton<LogService>(() => LogService(prefs));

        final container = ProviderContainer(
          overrides: [contentRepositoryProvider.overrideWithValue(mockRepo)],
        );

        final settings = container.read(settingsViewModelProvider.notifier);
        await settings.setSelectedProvider(AiProvider.gemini);
        await settings.setSelectedModel('gemini-1.5-flash');

        final vm = container.read(generateViewModelProvider.notifier);
        await vm.generatePost('Breaking football news article');

        final state = container.read(generateViewModelProvider);
        expect(state.status, GenerateState.success);
        expect(state.curatedPost, isNotNull);
        expect(
          container.read(settingsViewModelProvider).selectedProvider,
          AiProvider.groq,
        );
        expect(mockRepo.lastProvider, AiProvider.groq);
        expect(mockRepo.callCount, 2);
        // Inline provider-default model persisted for the fallback.
        expect(
          container.read(settingsViewModelProvider).selectedModel,
          AiProvider.groq.defaultModelId,
        );
        // Notice cleared on terminal success.
        expect(state.fallbackNotice, isNull);

        container.dispose();
      },
    );

    test('exhausted chain (no fallback keys) surfaces last-resort rateLimited '
        'state', () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final prefService = PreferencesService(
        prefs: prefs,
        secureStorage: storage,
      );
      await prefService.setApiKey(AiProvider.gemini, 'fake-gemini-key');
      await prefService.setSelectedModel(AiProvider.gemini, 'gemini-1.5-flash');
      // No keys for groq / openRouter / cerebras.

      final mockRepo = _MockContentRepository();
      mockRepo.queue(const ResultError(RateLimitFailure('429')));

      await getIt.reset();
      await configureDependencies();
      getIt.allowReassignment = true;
      getIt.registerLazySingleton<PreferencesService>(() => prefService);
      getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
      getIt.registerLazySingleton<LogService>(() => LogService(prefs));

      final container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(mockRepo)],
      );

      final settings = container.read(settingsViewModelProvider.notifier);
      await settings.setSelectedProvider(AiProvider.gemini);
      await settings.setSelectedModel('gemini-1.5-flash');

      final vm = container.read(generateViewModelProvider.notifier);
      await vm.generatePost('Breaking football news article');

      final state = container.read(generateViewModelProvider);
      expect(state.status, GenerateState.rateLimited);
      expect(state.suggestedFallbackProvider, AiProvider.groq);
      expect(state.errorMessage, contains('Rate limit exceeded'));
      expect(state.pendingInput, 'Breaking football news article');
      // Only the primary request fired — no doomed fallback attempts.
      expect(mockRepo.callCount, 1);
      expect(mockRepo.lastProvider, AiProvider.gemini);

      container.dispose();
    });

    test(
      'retryWithProvider without fallback key surfaces named error',
      () async {
        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        const storage = FlutterSecureStorage();
        final prefService = PreferencesService(
          prefs: prefs,
          secureStorage: storage,
        );
        await prefService.setApiKey(AiProvider.gemini, 'fake-gemini-key');
        await prefService.setSelectedModel(
          AiProvider.gemini,
          'gemini-1.5-flash',
        );
        // Intentionally no Groq key.

        final mockRepo = _MockContentRepository();
        mockRepo.queue(const ResultError(RateLimitFailure('429')));

        await getIt.reset();
        await configureDependencies();
        getIt.allowReassignment = true;
        getIt.registerLazySingleton<PreferencesService>(() => prefService);
        getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
        getIt.registerLazySingleton<LogService>(() => LogService(prefs));

        final container = ProviderContainer(
          overrides: [contentRepositoryProvider.overrideWithValue(mockRepo)],
        );

        final settings = container.read(settingsViewModelProvider.notifier);
        await settings.setSelectedProvider(AiProvider.gemini);
        await settings.setSelectedModel('gemini-1.5-flash');

        final vm = container.read(generateViewModelProvider.notifier);
        await vm.generatePost('Breaking football news article');
        expect(
          container.read(generateViewModelProvider).status,
          GenerateState.rateLimited,
        );

        final callsBefore = mockRepo.callCount;
        await vm.retryWithProvider(AiProvider.groq);

        // No doomed request fired; named configuration error instead.
        expect(mockRepo.callCount, callsBefore);
        final state = container.read(generateViewModelProvider);
        expect(state.status, GenerateState.error);
        expect(state.errorMessage, contains('Groq'));

        container.dispose();
      },
    );

    test('cooldown: subsequent generation skips the recently rate-limited '
        'provider entirely', () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final prefService = PreferencesService(
        prefs: prefs,
        secureStorage: storage,
      );
      await prefService.setApiKey(AiProvider.gemini, 'fake-gemini-key');
      await prefService.setSelectedModel(AiProvider.gemini, 'gemini-1.5-flash');
      await prefService.setApiKey(AiProvider.groq, 'fake-groq-key');
      await prefService.setSelectedModel(AiProvider.groq, 'llama-3.3-70b');

      final mockRepo = _MockContentRepository();
      // Call 1: gemini 429 → auto-fallback groq success.
      mockRepo.queue(const ResultError(RateLimitFailure('429')));
      // Calls 2 (fallback) and 3 (cooldown-skipped next generation): success.

      await getIt.reset();
      await configureDependencies();
      getIt.allowReassignment = true;
      getIt.registerLazySingleton<PreferencesService>(() => prefService);
      getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
      getIt.registerLazySingleton<LogService>(() => LogService(prefs));

      final container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(mockRepo)],
      );

      final settings = container.read(settingsViewModelProvider.notifier);
      await settings.setSelectedProvider(AiProvider.gemini);
      await settings.setSelectedModel('gemini-1.5-flash');

      final vm = container.read(generateViewModelProvider.notifier);
      await vm.generatePost('First generation');

      final vm2 = container.read(generateViewModelProvider.notifier);
      await vm2.generatePost('Second generation');

      expect(mockRepo.callCount, 3);
      // Request #1 hit gemini, then the auto-fallback and the
      // cooldown-skipped second generation both went straight to groq.
      expect(mockRepo.lastProvider, AiProvider.groq);
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.success,
      );

      container.dispose();
    });
  });
}
