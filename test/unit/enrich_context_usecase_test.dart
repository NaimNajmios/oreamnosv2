import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/tavily_search.dart';
import 'package:oreamnos/domain/repositories/search_repository.dart';
import 'package:oreamnos/domain/services/enrich_context_usecase.dart';
import 'package:oreamnos/domain/services/intent_classifier.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';

class _FakeUnconfiguredSearchRepository implements ISearchRepository {
  @override
  Future<bool> isConfigured() async => false;

  @override
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  }) async {
    throw Exception('Should not be called when unconfigured');
  }

  @override
  Future<String> extractFromUrl(String url) async {
    throw Exception('Should not be called when unconfigured');
  }
}

class _FakeFailingSearchRepository implements ISearchRepository {
  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  }) async {
    throw Exception('Tavily API 500 server error');
  }

  @override
  Future<String> extractFromUrl(String url) async {
    throw Exception('Tavily API 500 server error');
  }
}

class _FakeConfiguredSearchRepository implements ISearchRepository {
  final List<TavilySearchResult> results;
  final String answer;
  String? lastQuery;

  _FakeConfiguredSearchRepository({this.results = const [], this.answer = ''});

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  }) async {
    lastQuery = query;
    return TavilySearchResponse(query: query, answer: answer, results: results);
  }

  @override
  Future<String> extractFromUrl(String url) async => 'Article content';
}

void main() {
  group('EnrichContextUseCase resilience', () {
    test(
      'returns plain content when Tavily is unconfigured without throwing',
      () async {
        final repo = _FakeUnconfiguredSearchRepository();
        final scraper = WebScraperService(ApiClient());
        final usecase = EnrichContextUseCase(repo, scraper);

        final result = await usecase.execute(
          'JDT vs Selangor',
          InputIntent.shortQuery,
        );
        expect(result.content, 'JDT vs Selangor');
        expect(result.sources, isEmpty);
      },
    );

    test(
      'returns plain content when searchContext throws an exception',
      () async {
        final repo = _FakeFailingSearchRepository();
        final scraper = WebScraperService(ApiClient());
        final usecase = EnrichContextUseCase(repo, scraper);

        final result = await usecase.execute(
          'Arsenal tactical analysis',
          InputIntent.shortQuery,
        );
        expect(result.content, 'Arsenal tactical analysis');
        expect(result.sources, isEmpty);
      },
    );

    test('extractSearchQuery extracts concise query from headline or article', () {
      const article =
          'Bukayo Saka scored a stunning brace as Arsenal defeated Chelsea 3-1 at Emirates Stadium. The England international was phenomenal.';
      final query = EnrichContextUseCase.extractSearchQuery(article);
      expect(query, contains('Bukayo Saka'));
      expect(query, contains('stats'));
    });

    test('enriches fullArticle with verified research context and editorial guidelines', () async {
      final repo = _FakeConfiguredSearchRepository(
        results: [
          const TavilySearchResult(
            title: 'BBC Sport - Arsenal vs Chelsea Match Report',
            url: 'https://bbc.com/sport/football/12345',
            content: 'Bukayo Saka has now reached 15 goals in all competitions this season, his best tally.',
            score: 0.95,
          ),
        ],
        answer: 'Saka scored two goals, bringing his Premier League tally to 11 goals and 8 assists.',
      );
      final scraper = WebScraperService(ApiClient());
      final usecase = EnrichContextUseCase(repo, scraper);

      const articleText =
          'Bukayo Saka scored twice as Arsenal secured a massive 3-1 win over Chelsea today. Arteta praised the winger.';
      final result = await usecase.execute(
        articleText,
        InputIntent.fullArticle,
      );

      expect(result.sources, contains('https://bbc.com/sport/football/12345'));
      expect(
        result.content,
        contains('REAL-TIME RESEARCH CONTEXT & VERIFIED STATS'),
      );
      expect(result.content, contains('15 goals in all competitions'));
      expect(
        result.content,
        contains('EDITORIAL GUIDELINES FOR RESEARCH CONTEXT'),
      );
      expect(
        result.content,
        contains('STRICTLY FORBIDDEN: Do not add obvious commentary'),
      );
      expect(repo.lastQuery, contains('Bukayo Saka'));
    });
  });
}
