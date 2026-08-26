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
        final localScrape = await _webScraper.extractArticleFromUrlInternal(input);
        if (localScrape.text.length > 200) {
          return EnrichmentResult(content: localScrape.text, sources: [input]);
        }

        // Fallback to Tavily Extract
        final extracted = await _searchRepo.extractFromUrl(input);
        return EnrichmentResult(content: extracted, sources: [input]);
      } catch (_) {
        throw Exception('Failed to extract content from URL');
      }
    }

    // Short Query -> Search
    final searchResponse = await _searchRepo.searchContext(
      query: "football soccer $input",
      maxResults: 3,
    );

    final mergedContent = StringBuffer();
    mergedContent.writeln('USER QUERY: $input\n');
    mergedContent.writeln('REAL-TIME SEARCH CONTEXT:');

    final sources = <String>[];
    for (final result in searchResponse.results) {
      mergedContent.writeln('--- Source: ${result.title} (${result.url}) ---');
      mergedContent.writeln(result.content);
      sources.add(result.url);
    }

    if (searchResponse.answer.isNotEmpty) {
      mergedContent.writeln('\nAI SUMMARY: ${searchResponse.answer}');
    }

    return EnrichmentResult(
      content: mergedContent.toString(),
      sources: sources,
    );
  }
}
