import 'package:flutter/foundation.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/twitter_extractor.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';
import 'package:oreamnos/domain/repositories/search_repository.dart';

class TwitterArticleEnrichResult {
  final String content;
  final String url;

  const TwitterArticleEnrichResult({required this.content, required this.url});
}

class TwitterArticleEnricher {
  TwitterArticleEnricher([
    ISearchRepository? searchRepo,
    WebScraperService? webScraper,
  ]) : _searchRepo = searchRepo,
       _webScraper = webScraper;

  final ISearchRepository? _searchRepo;
  final WebScraperService? _webScraper;

  ISearchRepository get _resolvedSearchRepo =>
      _searchRepo ?? getIt<ISearchRepository>();
  WebScraperService get _resolvedWebScraper =>
      _webScraper ?? getIt<WebScraperService>();

  /// Attempts to extract content from the first external article link found in [tweetText].
  ///
  /// Priority:
  /// 1. Tavily Extract API via [ISearchRepository.extractFromUrl].
  /// 2. Local scraping via [WebScraperService.extractArticleFromUrlInternal].
  ///
  /// Returns [TwitterArticleEnrichResult] if substantive content (>100 chars) is found,
  /// or `null` if no external link exists or extraction fails.
  Future<TwitterArticleEnrichResult?> enrichFromTweet(String tweetText) async {
    final urls = TwitterExtractor.extractArticleUrls(tweetText);
    if (urls.isEmpty) return null;

    for (final url in urls) {
      // 1. Try Tavily Extract
      try {
        final tavilyContent = await _resolvedSearchRepo.extractFromUrl(url);
        final cleaned = tavilyContent.trim();
        if (cleaned.length > 100) {
          return TwitterArticleEnrichResult(
            url: url,
            content: _sanitizeAndTruncate(cleaned),
          );
        }
      } catch (e) {
        debugPrint('Tavily extract failed for $url, trying local scraper: $e');
      }

      // 2. Fallback to local WebScraperService
      try {
        final article = await _resolvedWebScraper.extractArticleFromUrlInternal(
          url,
        );
        final cleaned = article.text.trim();
        if (cleaned.length > 100 &&
            !cleaned.contains('No readable content found')) {
          return TwitterArticleEnrichResult(
            url: url,
            content: _sanitizeAndTruncate(cleaned),
          );
        }
      } catch (e) {
        debugPrint('WebScraper extract failed for $url: $e');
      }
    }

    return null;
  }

  static String _sanitizeAndTruncate(String text, {int maxLength = 3500}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength)}...';
  }
}
