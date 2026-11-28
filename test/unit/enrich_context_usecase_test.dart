import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/domain/models/query_plan_suggestion.dart';
import 'package:oreamnos/domain/models/research_context.dart';
import 'package:oreamnos/domain/models/tavily_search.dart';
import 'package:oreamnos/domain/repositories/search_repository.dart';
import 'package:oreamnos/domain/services/enrich_context_usecase.dart';
import 'package:oreamnos/domain/services/intent_classifier.dart';
import 'package:oreamnos/domain/services/query_planner_ai.dart';

class _FakeSearchRepository implements ISearchRepository {
  _FakeSearchRepository({
    this.configured = true,
    this.results = const [],
    this.failure,
  });

  final bool configured;
  final List<TavilySearchResult> results;
  final Failure? failure;
  final List<String> queries = [];

  @override
  Future<bool> isConfigured() async => configured;

  @override
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  }) async {
    final result = await search(
      SearchOptions(query: query, maxResults: maxResults),
    );
    return result.fold((data) => data, (failure) => throw failure);
  }

  @override
  Future<Result<TavilySearchResponse>> search(
    SearchOptions options, {
    CancelToken? cancelToken,
  }) async {
    queries.add(options.query);
    if (failure != null) return ResultError(failure!);
    return ResultSuccess(
      TavilySearchResponse(query: options.query, results: results, credits: 1),
    );
  }

  @override
  Future<String> extractFromUrl(String url) async => '';

  @override
  Future<Result<String>> extract(
    String url, {
    CancelToken? cancelToken,
    String? query,
  }) async => const ResultSuccess('');

  @override
  Future<SearchConnectionResult> testConnection({String? apiKey}) async =>
      const SearchConnectionResult.success();
}

class _FakeQueryPlannerAi extends QueryPlannerAi {
  _FakeQueryPlannerAi(this.suggestion);

  final QueryPlanSuggestion? suggestion;
  int calls = 0;

  @override
  Future<QueryPlanSuggestion?> plan({
    required String text,
    String? pageTitle,
    CancelToken? cancelToken,
  }) async {
    calls++;
    return suggestion;
  }
}

void main() {
  group('EnrichContextUseCase', () {
    test(
      'unconfigured returns plain content with unconfigured status',
      () async {
        final repo = _FakeSearchRepository(configured: false);
        final usecase = EnrichContextUseCase(
          repo,
          WebScraperService(ApiClient()),
        );

        final result = await usecase.execute(
          'JDT vs Selangor',
          InputIntent.shortQuery,
        );

        expect(result.content, 'JDT vs Selangor');
        expect(result.sources, isEmpty);
        expect(result.status, ResearchStatus.unconfigured);
        expect(repo.queries, isEmpty);
      },
    );

    test('search failure is surfaced instead of swallowed', () async {
      final repo = _FakeSearchRepository(
        failure: const AuthFailure('Tavily rejected the API key (401).'),
      );
      final usecase = EnrichContextUseCase(
        repo,
        WebScraperService(ApiClient()),
      );

      final result = await usecase.execute(
        'Arsenal tactical analysis',
        InputIntent.shortQuery,
      );

      expect(result.content, 'Arsenal tactical analysis');
      expect(result.status, ResearchStatus.failed);
      expect(result.message, contains('401'));
    });

    test('relevant results are merged into a research block and digest', () async {
      final repo = _FakeSearchRepository(
        results: const [
          TavilySearchResult(
            title: 'Bukayo Saka scores twice as Arsenal beat Chelsea 3-1',
            url: 'https://www.bbc.com/sport/football/12345',
            content: 'Bukayo Saka has now reached 15 goals in all competitions this season, his best tally.',
            score: 0.95,
            publishedDate: '2026-11-27T10:00:00Z',
          ),
        ],
      );
      final usecase = EnrichContextUseCase(
        repo,
        WebScraperService(ApiClient()),
      );

      const article =
          'Bukayo Saka scored twice as Arsenal secured a massive 3-1 win over Chelsea today. Arteta praised the winger.';
      final result = await usecase.execute(article, InputIntent.fullArticle);

      expect(result.status, ResearchStatus.ok);
      expect(
        result.sources,
        contains('https://www.bbc.com/sport/football/12345'),
      );
      expect(result.content, contains('REAL-TIME RESEARCH CONTEXT'));
      expect(result.content, contains('15 goals in all competitions'));
      expect(result.content, contains('BBC Sport'));
      expect(result.digest, contains('15 goals'));
      expect(result.query, contains('Bukayo Saka'));
      expect(result.credits, greaterThan(0));
    });

    test('high-score but unrelated results are rejected', () async {
      final repo = _FakeSearchRepository(
        results: const [
          TavilySearchResult(
            title: 'Kuala Lumpur traffic update',
            url: 'https://example.com/traffic',
            content: 'Road closures today around Kuala Lumpur city centre.',
            score: 0.99,
          ),
        ],
      );
      final usecase = EnrichContextUseCase(
        repo,
        WebScraperService(ApiClient()),
      );

      const article =
          'Bukayo Saka scored twice as Arsenal secured a massive 3-1 win over Chelsea today. Arteta praised the winger.';
      final result = await usecase.execute(article, InputIntent.fullArticle);

      expect(result.status, ResearchStatus.empty);
      expect(result.content, article);
      expect(result.sources, isEmpty);
      expect(result.message, contains('No relevant context found'));
    });

    test('skips research when the text has no player or club name', () async {
      final repo = _FakeSearchRepository();
      final usecase = EnrichContextUseCase(
        repo,
        WebScraperService(ApiClient()),
      );

      final result = await usecase.execute(
        'TYPE DATE Fri Nov POST CONTENT transfer news',
        InputIntent.fullArticle,
      );

      expect(result.status, ResearchStatus.empty);
      expect(result.message, contains('player or club name'));
      expect(repo.queries, isEmpty);
    });

    test('an edited query overrides the pasted text', () async {
      final repo = _FakeSearchRepository(
        results: const [
          TavilySearchResult(
            title: 'Max Dowman signs three-year Arsenal contract',
            url: 'https://www.bbc.com/sport/football/99999',
            content: 'Max Dowman has signed a three-year deal with Arsenal after turning 17.',
            score: 0.93,
          ),
        ],
      );
      final usecase = EnrichContextUseCase(
        repo,
        WebScraperService(ApiClient()),
      );

      const junkInput =
          'TYPE: Transfer\nDATE: Fri Nov\nPOST CONTENT: Max Dowman deal';
      final result = await usecase.execute(
        junkInput,
        InputIntent.fullArticle,
        queryOverride: 'Max Dowman Arsenal contract',
      );

      expect(result.status, ResearchStatus.ok);
      expect(result.query, contains('Max Dowman'));
      expect(repo.queries.first, contains('Max Dowman'));
    });

    test('planner prefers the headline and never blindly appends stats', () {
      const article =
          'Kuala Lumpur: Johor Darul Ta\'zim extended their unbeaten run with a 2-1 win over Selangor.';
      final query = EnrichContextUseCase.extractSearchQuery(article);
      expect(query, isNot(contains('stats')));
      expect(query.toLowerCase(), contains('johor'));
    });

    test('uses a Groq suggestion when available', () async {
      final repo = _FakeSearchRepository(
        results: const [
          TavilySearchResult(
            title: 'Max Dowman signs three-year Arsenal contract',
            url: 'https://www.bbc.com/sport/football/99999',
            content: 'Max Dowman has signed a three-year deal with Arsenal.',
            score: 0.93,
          ),
        ],
      );
      final ai = _FakeQueryPlannerAi(
        const QueryPlanSuggestion(
          entities: ['Max Dowman', 'Arsenal'],
          queries: ['Max Dowman Arsenal first professional contract'],
        ),
      );
      final usecase = EnrichContextUseCase(
        repo,
        WebScraperService(ApiClient()),
        queryPlannerAi: ai,
      );

      final result = await usecase.execute(
        'TYPE DATE Fri Nov POST CONTENT Max Dowman deal',
        InputIntent.fullArticle,
      );

      expect(ai.calls, 1);
      expect(result.status, ResearchStatus.ok);
      expect(result.query, 'Max Dowman Arsenal first professional contract');
      expect(result.diagnostic?.planner, 'groq');
    });

    test(
      'falls back to the heuristic planner when Groq returns nothing',
      () async {
        final repo = _FakeSearchRepository(
          results: const [
            TavilySearchResult(
              title: 'Bukayo Saka scores twice as Arsenal beat Chelsea 3-1',
              url: 'https://www.bbc.com/sport/football/12345',
              content:
                  'Bukayo Saka reached 15 goals this season as Arsenal won.',
              score: 0.95,
            ),
          ],
        );
        final ai = _FakeQueryPlannerAi(null);
        final usecase = EnrichContextUseCase(
          repo,
          WebScraperService(ApiClient()),
          queryPlannerAi: ai,
        );

        final result = await usecase.execute(
          'Bukayo Saka scored twice as Arsenal beat Chelsea 3-1.',
          InputIntent.fullArticle,
        );

        expect(ai.calls, 1);
        expect(result.status, ResearchStatus.ok);
        expect(result.query, contains('Bukayo Saka'));
        expect(result.diagnostic?.planner, 'heuristic');
      },
    );

    test('an edited query does not spend a Groq planner call', () async {
      final repo = _FakeSearchRepository(
        results: const [
          TavilySearchResult(
            title: 'Max Dowman signs three-year Arsenal contract',
            url: 'https://www.bbc.com/sport/football/99999',
            content: 'Max Dowman has signed a three-year deal with Arsenal.',
            score: 0.93,
          ),
        ],
      );
      final ai = _FakeQueryPlannerAi(
        const QueryPlanSuggestion(
          entities: ['Max Dowman'],
          queries: ['wrong query'],
        ),
      );
      final usecase = EnrichContextUseCase(
        repo,
        WebScraperService(ApiClient()),
        queryPlannerAi: ai,
      );

      await usecase.execute(
        'Max Dowman deal',
        InputIntent.fullArticle,
        queryOverride: 'Max Dowman Arsenal contract',
      );

      expect(ai.calls, 0);
      expect(repo.queries.first, contains('Max Dowman Arsenal contract'));
    });
  });
}
