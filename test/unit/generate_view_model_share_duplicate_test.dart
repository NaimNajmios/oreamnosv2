import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/repositories/content_repository.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/models/tavily_search.dart';
import 'package:oreamnos/domain/repositories/search_repository.dart';
import 'package:oreamnos/domain/services/enrich_context_usecase.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

class _SlowSearchRepository implements ISearchRepository {
  final Completer<TavilySearchResponse> gate =
      Completer<TavilySearchResponse>();
  int searchCalls = 0;

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  }) {
    searchCalls++;
    return gate.future;
  }

  @override
  Future<String> extractFromUrl(String url) async => '';

  @override
  Future<Result<TavilySearchResponse>> search(
    SearchOptions options, {
    CancelToken? cancelToken,
  }) async => ResultSuccess(
    await searchContext(
      query: options.query,
      maxResults: options.maxResults,
      includeAnswer: options.includeAnswer,
    ),
  );

  @override
  Future<Result<String>> extract(
    String url, {
    CancelToken? cancelToken,
    String? query,
  }) async => ResultSuccess(await extractFromUrl(url));

  @override
  Future<SearchConnectionResult> testConnection({String? apiKey}) async =>
      const SearchConnectionResult.success();
}

/// Keeps URL-driven share tests off the network: the published
/// [WebScraperService.extractArticleFromUrl] static delegates to the
/// registered instance, so overriding it is enough.
class _FakeWebScraperService extends WebScraperService {
  @override
  Future<ExtractedArticle> extractArticleFromUrlInternal(String url) async {
    return ExtractedArticle(
      text: 'Fake article body for $url',
      url: url,
      domain: 'example.com',
      pageTitle: 'Fake article',
      siteName: 'Example',
    );
  }
}

class _GatedRepository implements IContentRepository {
  final Completer<Result<CuratedPost>> _gate = Completer<Result<CuratedPost>>();
  int callCount = 0;

  void complete() {
    if (!_gate.isCompleted) {
      _gate.complete(
        const ResultSuccess(
          CuratedPost(
            title: 'Headline',
            bodyMarkdown: 'Body',
            hashtags: ['Tag'],
            source: SourceAttribution(label: 'source'),
            rawMarkdown: 'Raw',
          ),
        ),
      );
    }
  }

  @override
  Future<Result<CuratedPost>> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    required AiProvider provider,
    List<String> searchSources = const [],
    String? researchDigest,
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
    CancelToken? cancelToken,
  }) async {
    callCount++;
    return _gate.future;
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
    String length = 'medium',
    bool isFanModeEnabled = false,
    String fanClubName = '',
    String? researchDigest,
    CancelToken? cancelToken,
  }) async {
    callCount++;
    return _gate.future;
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

  group('Duplicate share handling', () {
    late ProviderContainer container;
    late _GatedRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final prefService = PreferencesService(
        prefs: prefs,
        secureStorage: storage,
      );
      await prefService.setApiKey(AiProvider.gemini, 'fake-key');
      await prefService.setSelectedModel(AiProvider.gemini, 'gemini-2.0-flash');

      await getIt.reset();
      await configureDependencies();
      getIt.allowReassignment = true;
      getIt.registerLazySingleton<PreferencesService>(() => prefService);
      getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
      getIt.registerLazySingleton<LogService>(() => LogService(prefs));
      getIt.registerLazySingleton<WebScraperService>(
        () => _FakeWebScraperService(),
      );

      repo = _GatedRepository();
      container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(repo)],
      );
      final settings = container.read(settingsViewModelProvider.notifier);
      await settings.setSelectedProvider(AiProvider.gemini);
      await settings.setSelectedModel('gemini-2.0-flash');
    });

    tearDown(() => container.dispose());

    test('a duplicate share while generating does not start a second '
        'generation', () async {
      final vm = container.read(generateViewModelProvider.notifier);
      // Plain text keeps the pipeline on the repository mock (a tweet URL
      // would detour into FxTwitter extraction).
      const link = 'plain text news';

      final first = vm.handleExternalSharedInput(link);
      // Let the pre-flight key lookup finish so the repository call is live.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.callCount, 1);

      // Android rebounces the same share after the service dedup window.
      await vm.handleExternalSharedInput(link);
      expect(repo.callCount, 1);
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.generating,
      );

      repo.complete();
      await first;
      expect(repo.callCount, 1);
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.success,
      );
    });

    test('the same content can be generated again after a new entry', () async {
      final vm = container.read(generateViewModelProvider.notifier);
      // Plain text keeps the pipeline on the repository mock (a tweet URL
      // would detour into FxTwitter extraction).
      const link = 'plain text news';

      final first = vm.handleExternalSharedInput(link);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      repo.complete();
      await first;
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.success,
      );

      // A replay of the same share is ignored while the finished post is on
      // screen; an explicit "New Entry" is what releases that ownership.
      vm.reset();
      final second = vm.handleExternalSharedInput(link);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.callCount, 2);
      repo.complete();
      await second;
    });

    test('a replay after success does not wipe the generated post', () async {
      final vm = container.read(generateViewModelProvider.notifier);
      const link = 'plain text news';

      final first = vm.handleExternalSharedInput(link);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      repo.complete();
      await first;
      final settled = container.read(generateViewModelProvider);
      expect(settled.status, GenerateState.success);
      expect(settled.curatedPost, isNotNull);

      // Same logical share in a different byte form (case + whitespace):
      // the VM dedups on the normalized share key, not the display text.
      await vm.handleExternalSharedInput('  Plain   TEXT   news  ');
      expect(repo.callCount, 1);
      final after = container.read(generateViewModelProvider);
      expect(after.status, GenerateState.success);
      expect(after.curatedPost, same(settled.curatedPost));
    });

    test('a duplicate share with different query params while generating is ignored', () async {
      final vm = container.read(generateViewModelProvider.notifier);
      const firstUrl = 'https://example.com/news/1?utm_source=x';
      const secondUrl = 'https://example.com/news/1?ref=share';

      final first = vm.handleExternalSharedInput(firstUrl);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await vm.handleExternalSharedInput(secondUrl);
      expect(repo.callCount, 1);
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.generating,
      );

      repo.complete();
      await first;
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.success,
      );
    });

    test('superseded research-mode session cannot overwrite a newer completed session back to generating', () async {
      final slowSearch = _SlowSearchRepository();
      getIt.registerFactory<EnrichContextUseCase>(
        () => EnrichContextUseCase(slowSearch, WebScraperService(ApiClient())),
      );

      final vm = container.read(generateViewModelProvider.notifier);
      vm.toggleResearchMode();

      // Session 1 pauses inside research enrichment.
      final first = vm.handleExternalSharedInput(
        'Max Dowman Arsenal contract transfer news',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(slowSearch.searchCalls, 1);

      // Session 2 supersedes Session 1 (with research disabled) and finishes.
      vm.toggleResearchMode();
      final second = vm.handleExternalSharedInput(
        'Selangor FC JDT match report',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      repo.complete();
      await second;
      expect(
        container.read(generateViewModelProvider).status,
        GenerateState.success,
      );
      expect(container.read(generateViewModelProvider).curatedPost, isNotNull);

      // Now Session 1's research await finally resolves; it must bail out
      // instead of overwriting Session 2's completed state back to generating.
      slowSearch.gate.complete(
        const TavilySearchResponse(query: 'q', answer: 'a', results: []),
      );
      await first;

      final finalState = container.read(generateViewModelProvider);
      expect(finalState.status, GenerateState.success);
      expect(finalState.curatedPost, isNotNull);
      expect(repo.callCount, 1);
    });
  });
}
