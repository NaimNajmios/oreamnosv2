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
  });
}
