import '../../config/constants.dart';
import '../models/research_context.dart';
import '../models/tavily_search.dart';
import 'football_search_lexicon.dart';
import 'search_relevance_guard.dart';

class ScoredSearchResult {
  const ScoredSearchResult({required this.result, required this.decision});

  final TavilySearchResult result;
  final SearchGuardDecision decision;
}

/// Deduplicates, orders and caps guarded results.
class SearchResultRanker {
  const SearchResultRanker();

  List<ResearchSource> rank(
    List<ScoredSearchResult> scored, {
    int maxSources = AppConstants.tavilyMaxSources,
    int maxChars = AppConstants.tavilyMaxContextChars,
  }) {
    final kept = scored.where((s) => s.decision.keep).toList()
      ..sort((a, b) {
        final byRelevance = b.decision.relevance.compareTo(
          a.decision.relevance,
        );
        if (byRelevance != 0) return byRelevance;
        return _date(b.result).compareTo(_date(a.result));
      });

    final byCanonical = <String, ScoredSearchResult>{};
    final seenTitles = <String>{};
    for (final item in kept) {
      final canonical = canonicalUrl(item.result.url);
      final titleKey = _normalizeTitle(item.result.title);
      if (byCanonical.containsKey(canonical)) continue;
      if (titleKey.isNotEmpty && seenTitles.contains(titleKey)) continue;
      byCanonical[canonical] = item;
      if (titleKey.isNotEmpty) seenTitles.add(titleKey);
    }

    final sources = <ResearchSource>[];
    var usedChars = 0;
    for (final item in byCanonical.values) {
      final snippet = _snippet(item.result);
      if (snippet.isEmpty) continue;
      if (sources.isNotEmpty && usedChars + snippet.length > maxChars) break;
      final outlet = _outlet(item.result);
      sources.add(
        ResearchSource(
          title: item.result.title.trim(),
          url: item.result.url.trim(),
          snippet: snippet,
          outlet: outlet,
          publishedDate: item.result.publishedDate,
          score: item.result.score,
        ),
      );
      usedChars += snippet.length;
      if (sources.length >= maxSources) break;
    }
    return sources;
  }

  /// Lowercased host + path with tracking params removed and no trailing `/`.
  static String canonicalUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return url.trim().toLowerCase();
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    var path = uri.path;
    while (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }
    final params =
        uri.queryParameters.entries
            .where((e) => !_trackingParams.contains(e.key.toLowerCase()))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final query = params.isEmpty
        ? ''
        : '?${params.map((e) => '${e.key}=${e.value}').join('&')}';
    return '$host$path$query';
  }

  static const Set<String> _trackingParams = {
    'fbclid',
    'gclid',
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'ref',
    'src',
    'cmpid',
    'ocid',
  };

  String _snippet(TavilySearchResult result) {
    var text = result.content.trim();
    if (text.length < 200) {
      final raw = result.rawContent?.trim() ?? '';
      if (raw.length > text.length) text = raw;
    }
    if (text.length > 900) text = '${text.substring(0, 900).trim()}…';
    return text;
  }

  String _outlet(TavilySearchResult result) {
    final known = FootballSearchLexicon.outletForDomain(result.url);
    if (known.isNotEmpty) return known;

    final title = result.title.trim();
    for (final sep in [' | ', ' – ', ' — ', ' - ', ' :: ', ' • ']) {
      if (!title.contains(sep)) continue;
      final last = title.split(sep).last.trim();
      if (last.isEmpty || last.length > 40) continue;
      if (last.contains('.') || last.contains('/')) continue;
      if (last.toLowerCase() == result.url.toLowerCase()) continue;
      return last;
    }
    return '';
  }

  DateTime _date(TavilySearchResult result) {
    final raw = result.publishedDate;
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
