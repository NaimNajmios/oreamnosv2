import 'package:injectable/injectable.dart';

import '../../data/services/web_scraper_service.dart';
import '../repositories/search_repository.dart';
import 'intent_classifier.dart';

class EnrichmentResult {
  final String content;
  final List<String> sources;
  EnrichmentResult({required this.content, required this.sources});
}

@injectable
class EnrichContextUseCase {
  EnrichContextUseCase(this._searchRepo, this._webScraper);

  final ISearchRepository _searchRepo;
  final WebScraperService _webScraper;

  /// Returns the original text + appended search context
  Future<EnrichmentResult> execute(String input, InputIntent intent) async {
    if (intent == InputIntent.fullArticle) {
      return EnrichmentResult(content: input, sources: []);
    }

    if (intent == InputIntent.url) {
      try {
        // Try local scrape first
        final localScrape = await _webScraper.extractArticleFromUrlInternal(
          input,
        );
        if (localScrape.text.length > 200) {
          return EnrichmentResult(content: localScrape.text, sources: [input]);
        }

        // Fallback to Tavily Extract if available
        if (await _searchRepo.isConfigured()) {
          final extracted = await _searchRepo.extractFromUrl(input);
          return EnrichmentResult(content: extracted, sources: [input]);
        }
        return EnrichmentResult(
          content: localScrape.text.isNotEmpty ? localScrape.text : input,
          sources: [input],
        );
      } catch (_) {
        return EnrichmentResult(content: input, sources: [input]);
      }
    }

    // Short Query -> Search
    try {
      if (!await _searchRepo.isConfigured()) {
        return EnrichmentResult(content: input, sources: []);
      }

      final searchResponse = await _searchRepo.searchContext(
        query: "football soccer $input",
        maxResults: 3,
      );

      final mergedContent = StringBuffer();
      mergedContent.writeln('USER QUERY: $input\n');
      mergedContent.writeln('REAL-TIME SEARCH CONTEXT:');

      final sources = <String>[];
      for (final result in searchResponse.results) {
        mergedContent.writeln('--- Source: ${result.title} ---');
        mergedContent.writeln(
          'URL (INTERNAL ONLY, grounding reference — never use as source.label): '
          '${result.url}',
        );
        mergedContent.writeln(result.content);
        sources.add(result.url);
      }
      mergedContent.writeln(
        'SOURCE RULE: Derive source.label ONLY from outlet names in the content above. NEVER use a URL, domain, or platform name as the citation.',
      );

      if (searchResponse.answer.isNotEmpty) {
        mergedContent.writeln('\nAI SUMMARY: ${searchResponse.answer}');
      }

      return EnrichmentResult(
        content: mergedContent.toString(),
        sources: sources,
      );
    } catch (_) {
      // Graceful degradation when search fails or Tavily key is missing
      return EnrichmentResult(content: input, sources: []);
    }
  }
}
