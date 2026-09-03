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

class _MockContentRepository implements IContentRepository {
  int callCount = 0;
  AiProvider? lastProvider;
  Failure? failureToReturn;

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
  }) async {
    callCount++;
    lastProvider = provider;
    if (failureToReturn != null) {
      return ResultError(failureToReturn!);
    }
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
  Future<Result<String>> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    required String tone,
    required String defaultHashtags,
  }) async {
    return const ResultSuccess('Plain text');
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

    test('RateLimitFailure transitions state to rateLimited with suggested fallback', () async {
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

      final mockRepo = _MockContentRepository()
        ..failureToReturn = const RateLimitFailure('429 Resource Exhausted');

      await getIt.reset();
      await configureDependencies();
      getIt.allowReassignment = true;
      getIt.registerLazySingleton<PreferencesService>(() => prefService);
      getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
      getIt.registerLazySingleton<LogService>(() => LogService(prefs));

      final container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(mockRepo)],
      );

      // Initialize settings state with selected model
      final settings = container.read(settingsViewModelProvider.notifier);
      await settings.setSelectedProvider(AiProvider.gemini);
      await settings.setSelectedModel('gemini-1.5-flash');
      await settings.setApiKey(AiProvider.gemini, 'fake-gemini-key');

      final vm = container.read(generateViewModelProvider.notifier);
      await vm.generatePost('Breaking football news article');

      final state = container.read(generateViewModelProvider);
      expect(state.status, GenerateState.rateLimited);
      expect(state.suggestedFallbackProvider, AiProvider.groq);
      expect(state.errorMessage, contains('Rate limit exceeded'));
      expect(state.pendingInput, 'Breaking football news article');

      // Now test retryWithProvider using the fallback
      mockRepo.failureToReturn = null; // Next attempt succeeds
      await vm.retryWithProvider(state.suggestedFallbackProvider!);

      final successState = container.read(generateViewModelProvider);
      expect(successState.status, GenerateState.success);
      expect(successState.curatedPost, isNotNull);
      expect(
        container.read(settingsViewModelProvider).selectedProvider,
        AiProvider.groq,
      );
      expect(mockRepo.lastProvider, AiProvider.groq);

      container.dispose();
    });
  });
}
