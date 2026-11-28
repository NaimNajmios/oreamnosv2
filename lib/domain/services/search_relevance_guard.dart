import '../../config/constants.dart';
import '../models/tavily_search.dart';
import 'football_search_lexicon.dart';
import 'search_query_planner.dart';

/// Why a result was kept or dropped. Stored in search diagnostics.
class SearchGuardDecision {
  const SearchGuardDecision({
    required this.keep,
    required this.relevance,
    required this.reason,
    this.entityOverlap = 0,
    this.headlineOverlap = 0,
  });

  final bool keep;
  final double relevance;
  final String reason;
  final double entityOverlap;
  final double headlineOverlap;
}

/// Relevance gate between Tavily and the prompt.
///
/// Tavily's own `score` is an embedding similarity to the *query*. If the
/// query was vague, a high-scoring result can still be about a different
/// story. The guard therefore requires both a score floor and lexical overlap
/// with the article's entities/headline, which is what prevents "completely
/// unrelated" sources from being injected.
class SearchRelevanceGuard {
  const SearchRelevanceGuard();

  SearchGuardDecision evaluate({
    required TavilySearchResult result,
    required SearchPlan plan,
    double minScore = AppConstants.tavilyMinScore,
    bool relaxed = false,
  }) {
    if (FootballSearchLexicon.isExcludedDomain(result.url)) {
      return const SearchGuardDecision(
        keep: false,
        relevance: 0,
        reason: 'excluded domain',
      );
    }

    final trusted = FootballSearchLexicon.isTrustedDomain(result.url);
    final title = result.title.toLowerCase();
    if (!trusted) {
      for (final marker in FootballSearchLexicon.noiseTitleMarkers) {
        if (title.contains(marker)) {
          return const SearchGuardDecision(
            keep: false,
            relevance: 0,
            reason: 'noise title',
          );
        }
      }
    }

    if (result.score < minScore) {
      return SearchGuardDecision(
        keep: false,
        relevance: result.score,
        reason: 'score below floor',
      );
    }

    final text = '${result.title} ${result.content}';
    final resultTokens = _tokens(text);
    final entityOverlap = _entityOverlap(plan.entities, text);
    final headlineOverlap = _jaccard(_tokens(plan.headline), resultTokens);

    final entityFloor = relaxed ? 0.34 : 0.5;
    final headlineFloor = relaxed ? 0.16 : 0.3;
    final trustedDiscount = trusted ? 0.1 : 0.0;

    final matches = plan.entities.isEmpty
        ? headlineOverlap >= (relaxed ? 0.1 : 0.18)
        : entityOverlap >= (entityFloor - trustedDiscount) ||
              headlineOverlap >= (headlineFloor - trustedDiscount);

    final relevance =
        (result.score * 0.55) +
        (entityOverlap * 0.3) +
        (headlineOverlap * 0.15) +
        (trusted ? 0.05 : 0.0);

    return SearchGuardDecision(
      keep: matches,
      relevance: relevance,
      reason: matches ? 'relevant' : 'no entity/headline overlap',
      entityOverlap: entityOverlap,
      headlineOverlap: headlineOverlap,
    );
  }

  double _entityOverlap(List<String> entities, String text) {
    if (entities.isEmpty) return 0;
    final lower = text.toLowerCase();
    var hits = 0;
    for (final entity in entities) {
      final parts = entity
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((p) => p.length > 2)
          .toList();
      if (parts.isEmpty) continue;
      final matched = parts.any(lower.contains);
      if (matched) hits++;
    }
    return hits / entities.length;
  }

  Set<String> _tokens(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .where((t) => !FootballSearchLexicon.stopwords.contains(t))
        .toSet();
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0 : intersection / union;
  }
}
