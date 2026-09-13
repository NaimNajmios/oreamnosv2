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

  /// Extracts a targeted search query from longer content or article text.
  static String extractSearchQuery(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'https?://\S+'), '')
        .replaceAll(RegExp(r'[#@]\w+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return 'football soccer stats';

    // If input is already short (< 100 chars), use it directly
    if (cleaned.length <= 100) {
      return '$cleaned stats';
    }

    // For longer text, extract the first informative headline or sentence
    final sentences = cleaned
        .split(RegExp(r'[.!?\n]'))
        .map((s) => s.trim())
        .where((s) => s.length >= 15)
        .toList();

    if (sentences.isNotEmpty) {
      var candidate = sentences.first;
      if (candidate.length > 120) {
        candidate = candidate.substring(0, 120).trim();
      }
      return '$candidate stats';
    }

    return '${cleaned.substring(0, cleaned.length > 80 ? 80 : cleaned.length).trim()} stats';
  }

  /// Returns the original text + appended search context
  Future<EnrichmentResult> execute(String input, InputIntent intent) async {
    if (intent == InputIntent.fullArticle) {
      try {
        if (!await _searchRepo.isConfigured()) {
          return EnrichmentResult(content: input, sources: []);
        }

        final query = extractSearchQuery(input);
        final searchResponse = await _searchRepo.searchContext(
          query: query,
          maxResults: 3,
        );

        if (searchResponse.results.isEmpty && searchResponse.answer.isEmpty) {
          return EnrichmentResult(content: input, sources: []);
        }

        final mergedContent = StringBuffer();
        mergedContent.writeln('ORIGINAL ARTICLE / POST CONTENT:');
        mergedContent.writeln(input);
        mergedContent.writeln(
          '\n---\nREAL-TIME RESEARCH CONTEXT & VERIFIED STATS:',
        );

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
        if (searchResponse.answer.isNotEmpty) {
          mergedContent.writeln(
            '\nAI SUMMARY OF KEY FACTS: ${searchResponse.answer}',
          );
        }
        mergedContent.writeln(
          '\nEDITORIAL GUIDELINES FOR RESEARCH CONTEXT:\n'
          '1. Incorporate concrete supporting facts, relevant season stats, milestones, or head-to-head records from the research above to substantiate the post.\n'
          '2. STRICTLY FORBIDDEN: Do not add obvious commentary, superficial verdicts, or meaningless platitudes (e.g., "This goal was very important for the team", "Kemenangan ini amat bermakna", "Pemain ini membuktikan kehebatannya").\n'
          '3. Focus 100% on high-value facts, figures, and verified details.',
        );

        return EnrichmentResult(
          content: mergedContent.toString(),
          sources: sources,
        );
      } catch (_) {
        return EnrichmentResult(content: input, sources: []);
      }
    }

    if (intent == InputIntent.url) {
      try {
        // Try local scrape first
        final localScrape = await _webScraper.extractArticleFromUrlInternal(
          input,
        );
        var content = localScrape.text;
        if (content.length <= 200 && await _searchRepo.isConfigured()) {
          // Fallback to Tavily Extract if available
          final extracted = await _searchRepo.extractFromUrl(input);
          if (extracted.trim().length > content.length) {
            content = extracted;
          }
        }

        final sources = [input];

        // If Tavily search is configured and article text is available, enrich with research stats
        if (await _searchRepo.isConfigured() &&
            content.trim().isNotEmpty &&
            content != input) {
          try {
            final query = extractSearchQuery(content);
            final searchResponse = await _searchRepo.searchContext(
              query: query,
              maxResults: 2,
            );
            if (searchResponse.results.isNotEmpty ||
                searchResponse.answer.isNotEmpty) {
              final mergedContent = StringBuffer();
              mergedContent.writeln('ORIGINAL ARTICLE:');
              mergedContent.writeln(content);
              mergedContent.writeln(
                '\n---\nREAL-TIME RESEARCH CONTEXT & VERIFIED STATS:',
              );
              for (final result in searchResponse.results) {
                mergedContent.writeln('--- Source: ${result.title} ---');
                mergedContent.writeln(result.content);
                if (!sources.contains(result.url)) sources.add(result.url);
              }
              if (searchResponse.answer.isNotEmpty) {
                mergedContent.writeln(
                  '\nKEY STATS & FACTS: ${searchResponse.answer}',
                );
              }
              mergedContent.writeln(
                '\nEDITORIAL GUIDELINES FOR RESEARCH CONTEXT:\n'
                '1. Incorporate concrete supporting facts, relevant season stats, milestones, or head-to-head records from the research above.\n'
                '2. STRICTLY FORBIDDEN: Do not add obvious commentary, superficial verdicts, or meaningless platitudes.\n'
                '3. Focus 100% on high-value facts, figures, and verified details.',
              );
              return EnrichmentResult(
                content: mergedContent.toString(),
                sources: sources,
              );
            }
          } catch (_) {}
        }

        return EnrichmentResult(
          content: content.isNotEmpty ? content : input,
          sources: sources,
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

      mergedContent.writeln(
        '\nEDITORIAL GUIDELINES FOR RESEARCH CONTEXT:\n'
        '1. Incorporate concrete supporting facts, relevant season stats, milestones, or head-to-head records from the research above.\n'
        '2. STRICTLY FORBIDDEN: Do not add obvious commentary, superficial verdicts, or meaningless platitudes.\n'
        '3. Focus 100% on high-value facts, figures, and verified details.',
      );

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
