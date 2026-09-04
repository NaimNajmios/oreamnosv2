import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/twitter_article_enricher.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/models/tavily_search.dart';
import 'package:oreamnos/domain/repositories/search_repository.dart';

class FakeSearchRepository implements ISearchRepository {
  final Future<String> Function(String url)? onExtract;

  FakeSearchRepository({this.onExtract});

  @override
  Future<String> extractFromUrl(String url) async {
    if (onExtract != null) return onExtract!(url);
    throw Exception('Tavily API key not configured');
  }

  @override
  Future<TavilySearchResponse> searchContext({
    required String query,
    int maxResults = 3,
    bool includeAnswer = true,
  }) async {
    throw UnimplementedError();
  }
}

class FakeWebScraperService extends WebScraperService {
  final Future<ExtractedArticle> Function(String url)? onExtract;

  FakeWebScraperService({this.onExtract}) : super(ApiClient());

  @override
  Future<ExtractedArticle> extractArticleFromUrlInternal(String url) async {
    if (onExtract != null) return onExtract!(url);
    return ExtractedArticle(
      text: 'Fallback scraped article content that is long enough to be substantive and helpful for generation.',
      url: url,
      domain: 'example.com',
    );
  }
}

void main() {
  group('TwitterArticleEnricher', () {
    test('returns null when tweet has no URLs', () async {
      final enricher = TwitterArticleEnricher(
        FakeSearchRepository(),
        FakeWebScraperService(),
      );

      final result = await enricher.enrichFromTweet('Tweet without any link');
      expect(result, isNull);
    });

    test('extracts via Tavily when Tavily succeeds', () async {
      final fakeSearch = FakeSearchRepository(
        onExtract: (url) async {
          return 'Tavily extracted deep report on the tactical setup and team selection details for the upcoming clash.';
        },
      );
      final enricher = TwitterArticleEnricher(
        fakeSearch,
        FakeWebScraperService(),
      );

      final result = await enricher.enrichFromTweet(
        'Check out the report: https://theathletic.com/tactics/match',
      );

      expect(result, isNotNull);
      expect(result!.url, 'https://theathletic.com/tactics/match');
      expect(result.content, contains('Tavily extracted deep report'));
    });

    test('falls back to WebScraperService when Tavily throws', () async {
      final fakeSearch = FakeSearchRepository(
        onExtract: (url) async {
          throw Exception('Tavily quota exceeded or missing API key');
        },
      );
      final fakeScraper = FakeWebScraperService(
        onExtract: (url) async {
          return ExtractedArticle(
            text: 'Locally scraped article content providing extensive details regarding the transfer saga and player fee negotiations.',
            url: url,
            domain: 'theathletic.com',
          );
        },
      );

      final enricher = TwitterArticleEnricher(fakeSearch, fakeScraper);

      final result = await enricher.enrichFromTweet(
        'Latest update: https://theathletic.com/transfer/update',
      );

      expect(result, isNotNull);
      expect(result!.url, 'https://theathletic.com/transfer/update');
      expect(result.content, contains('Locally scraped article content'));
    });

    test('returns null when both Tavily and WebScraper fail', () async {
      final fakeSearch = FakeSearchRepository(
        onExtract: (url) async {
          throw Exception('Tavily failed');
        },
      );
      final fakeScraper = FakeWebScraperService(
        onExtract: (url) async {
          throw Exception('Web scraper failed');
        },
      );

      final enricher = TwitterArticleEnricher(fakeSearch, fakeScraper);

      final result = await enricher.enrichFromTweet(
        'Link to article: https://example.com/failed',
      );

      expect(result, isNull);
    });

    test('truncates content exceeding 3500 characters', () async {
      final hugeContent = 'A' * 5000;
      final fakeSearch = FakeSearchRepository(
        onExtract: (url) async => hugeContent,
      );

      final enricher = TwitterArticleEnricher(
        fakeSearch,
        FakeWebScraperService(),
      );

      final result = await enricher.enrichFromTweet(
        'Read: https://example.com/huge',
      );

      expect(result, isNotNull);
      expect(result!.content.length, lessThanOrEqualTo(3503)); // 3500 + '...'
      expect(result.content.endsWith('...'), isTrue);
    });
  });
}
