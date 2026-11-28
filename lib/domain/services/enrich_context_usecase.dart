import 'dart:async';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../config/constants.dart';
import '../../core/error/failures.dart';
import '../../data/services/web_scraper_service.dart';
import '../models/research_context.dart';
import '../models/tavily_search.dart';
import '../repositories/search_repository.dart';
import 'intent_classifier.dart';
import 'search_query_planner.dart';
import 'search_relevance_guard.dart';
import 'search_result_ranker.dart';

class EnrichmentResult {
  EnrichmentResult({
    required this.content,
    required this.sources,
    this.status = ResearchStatus.ok,
    this.message,
    this.query,
    this.sourceDetails = const [],
    this.credits = 0,
    this.digest,
    this.diagnostic,
  });

  /// Prompt-ready content (original text + research block).
  final String content;

  /// Source URLs (backward-compatible with the source chips/attribution).
  final List<String> sources;

  final ResearchStatus status;
  final String? message;
  final String? query;
  final List<ResearchSource> sourceDetails;
  final int credits;
  final String? digest;
  final SearchDiagnosticEntry? diagnostic;

  bool get hasSources => sourceDetails.isNotEmpty;
}

/// Orchestrates: query plan → Tavily search → relevance guard → rank →
/// optional extract → prompt block/digest.
///
/// Research is opt-in at the ViewModel level; this class is only called while
/// the toggle is on. Every failure returns the original content plus a typed
/// [ResearchStatus] instead of silently swallowing the error.
@injectable
class EnrichContextUseCase {
  EnrichContextUseCase(
    this._searchRepo,
    this._webScraper, {
    // Named `diagnostics` is part of the public API and the generated DI
    // configuration, so an initializing formal is intentionally avoided.
    // ignore: prefer_initializing_formals
    SearchDiagnosticsRecorder diagnostics =
        const NoopSearchDiagnosticsRecorder(),
  })
    // ignore: prefer_initializing_formals
    : _diagnostics = diagnostics;

  final ISearchRepository _searchRepo;
  final WebScraperService _webScraper;
  final SearchDiagnosticsRecorder _diagnostics;
  final SearchQueryPlanner _planner = const SearchQueryPlanner();
  final SearchRelevanceGuard _guard = const SearchRelevanceGuard();
  final SearchResultRanker _ranker = const SearchResultRanker();

  /// Extracts the primary search query for [text]. Kept for callers/tests that
  /// only need the planner's first query.
  static String extractSearchQuery(String text) {
    return const SearchQueryPlanner().plan(text: text).primary.query;
  }

  Future<EnrichmentResult> execute(
    String input,
    InputIntent intent, {
    String? pageTitle,
    String? description,
    String? preExtractedText,
    CancelToken? cancelToken,
  }) async {
    final result = await _execute(
      input,
      intent,
      pageTitle: pageTitle,
      description: description,
      preExtractedText: preExtractedText,
      cancelToken: cancelToken,
    );
    final diagnostic = result.diagnostic;
    if (diagnostic != null) _diagnostics.record(diagnostic);
    return result;
  }

  Future<EnrichmentResult> _execute(
    String input,
    InputIntent intent, {
    String? pageTitle,
    String? description,
    String? preExtractedText,
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      return _plain(input, ResearchStatus.cancelled, 'Research cancelled.');
    }

    if (!await _searchRepo.isConfigured()) {
      return _plain(
        input,
        ResearchStatus.unconfigured,
        'Add a Tavily key in Settings to use web research.',
      );
    }

    if (intent == InputIntent.url) {
      return _executeUrl(
        input,
        pageTitle: pageTitle,
        description: description,
        preExtractedText: preExtractedText,
        cancelToken: cancelToken,
      );
    }

    return _executeText(
      input,
      intent: intent,
      pageTitle: pageTitle,
      description: description,
      cancelToken: cancelToken,
    );
  }

  Future<EnrichmentResult> _executeUrl(
    String input, {
    String? pageTitle,
    String? description,
    String? preExtractedText,
    CancelToken? cancelToken,
  }) async {
    try {
      var content = (preExtractedText ?? '').trim();
      if (content.isEmpty) {
        final local = await _webScraper.extractArticleFromUrlInternal(input);
        content = local.text.trim();
        pageTitle ??= local.pageTitle;
        description ??= local.description;
      }

      if (content.length <= 200) {
        final extracted = await _searchRepo.extract(
          input,
          cancelToken: cancelToken,
        );
        final fallback = extracted.dataOrNull?.trim() ?? '';
        if (fallback.length > content.length) content = fallback;
      }

      if (content.isEmpty || content == input) {
        return _plain(
          input,
          ResearchStatus.empty,
          'Could not read this page, so no research was added.',
        );
      }

      return await _research(
        originalContent: content,
        queryText: content,
        pageTitle: pageTitle,
        description: description,
        intent: InputIntent.url,
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (cancelToken?.isCancelled ?? false) {
        return _plain(input, ResearchStatus.cancelled, 'Research cancelled.');
      }
      return _plain(
        input,
        ResearchStatus.failed,
        mapSearchException(e).message,
      );
    }
  }

  Future<EnrichmentResult> _executeText(
    String input, {
    required InputIntent intent,
    String? pageTitle,
    String? description,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _research(
        originalContent: input,
        queryText: input,
        pageTitle: pageTitle,
        description: description,
        intent: intent,
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (cancelToken?.isCancelled ?? false) {
        return _plain(input, ResearchStatus.cancelled, 'Research cancelled.');
      }
      return _plain(
        input,
        ResearchStatus.failed,
        mapSearchException(e).message,
      );
    }
  }

  Future<EnrichmentResult> _research({
    required String originalContent,
    required String queryText,
    required InputIntent intent,
    String? pageTitle,
    String? description,
    CancelToken? cancelToken,
  }) async {
    final plan = _planner.plan(
      text: queryText,
      pageTitle: pageTitle,
      description: description,
    );

    try {
      final run = await _runQueries(
        plan,
        cancelToken: cancelToken,
      ).timeout(AppConstants.tavilyResearchBudget);

      if (cancelToken?.isCancelled ?? false) {
        return _plain(
          originalContent,
          ResearchStatus.cancelled,
          'Research cancelled.',
          query: plan.primary.query,
          intent: plan.intent,
          topic: plan.primary.options.topic,
        );
      }
      if (run.failure != null && run.sources.isEmpty) {
        return _plain(
          originalContent,
          ResearchStatus.failed,
          run.failure!.message,
          query: plan.primary.query,
          intent: plan.intent,
          topic: plan.primary.options.topic,
          failureKind: run.failure.runtimeType.toString(),
          resultCount: run.resultCount,
          credits: run.credits,
          decisions: run.decisions,
          requestId: run.requestId,
          responseTime: run.responseTime,
        );
      }
      if (run.sources.isEmpty) {
        return _plain(
          originalContent,
          ResearchStatus.empty,
          'No relevant sources found for "${plan.primary.query}".',
          query: plan.primary.query,
          intent: plan.intent,
          topic: plan.primary.options.topic,
          resultCount: run.resultCount,
          credits: run.credits,
          decisions: run.decisions,
          requestId: run.requestId,
          responseTime: run.responseTime,
        );
      }

      var sources = run.sources;
      sources = await _extractThinSources(
        sources,
        query: plan.primary.query,
        intent: plan.intent,
        cancelToken: cancelToken,
      );

      final digest = _buildDigest(sources);
      return EnrichmentResult(
        content: _compose(
          originalContent: originalContent,
          sources: sources,
          isUrl: intent == InputIntent.url,
        ),
        sources: sources.map((s) => s.url).toList(),
        status: ResearchStatus.ok,
        message: '${sources.length} relevant source(s)',
        query: plan.primary.query,
        sourceDetails: sources,
        credits: run.credits,
        digest: digest,
        diagnostic: SearchDiagnosticEntry(
          at: DateTime.now(),
          status: ResearchStatus.ok,
          query: plan.primary.query,
          intent: plan.intent,
          topic: plan.primary.options.topic,
          resultCount: run.resultCount,
          keptCount: sources.length,
          credits: run.credits,
          message: '${sources.length} relevant source(s)',
          requestId: run.requestId,
          responseTime: run.responseTime,
          decisions: run.decisions,
        ),
      );
    } on TimeoutException {
      return _plain(
        originalContent,
        ResearchStatus.failed,
        'Web research took too long (${AppConstants.tavilyResearchBudget.inSeconds}s).',
        query: plan.primary.query,
        intent: plan.intent,
        topic: plan.primary.options.topic,
        failureKind: 'TimeoutException',
      );
    }
  }

  Future<_ResearchRun> _runQueries(
    SearchPlan plan, {
    CancelToken? cancelToken,
  }) async {
    var credits = 0;
    var resultCount = 0;
    String? requestId;
    double? responseTime;
    final collected = <TavilySearchResult>[];

    final primary = await _searchRepo.search(
      plan.primary.options,
      cancelToken: cancelToken,
    );
    if (primary is ResultError<TavilySearchResponse>) {
      return _ResearchRun(
        sources: const [],
        credits: credits,
        failure: primary.failure,
      );
    }
    final primaryData = (primary as ResultSuccess<TavilySearchResponse>).data;
    credits += primaryData.credits;
    collected.addAll(primaryData.results);
    resultCount += primaryData.results.length;
    requestId = primaryData.requestId;
    responseTime = primaryData.responseTime;

    var guarded = _guardAndRank(collected, plan);
    var sources = guarded.sources;
    if (sources.length >= 2 || plan.alternatives.isEmpty) {
      return _ResearchRun(
        sources: sources,
        credits: credits,
        resultCount: resultCount,
        requestId: requestId,
        responseTime: responseTime,
        decisions: guarded.decisions,
      );
    }

    // Only spend alternative-query credits when the primary query was thin.
    final alternatives = await Future.wait(
      plan.alternatives.map(
        (q) => _searchRepo.search(q.options, cancelToken: cancelToken),
      ),
    );
    for (final result in alternatives) {
      if (result is ResultSuccess<TavilySearchResponse>) {
        credits += result.data.credits;
        collected.addAll(result.data.results);
        resultCount += result.data.results.length;
        requestId ??= result.data.requestId;
      }
    }
    guarded = _guardAndRank(collected, plan);
    return _ResearchRun(
      sources: guarded.sources,
      credits: credits,
      resultCount: resultCount,
      requestId: requestId,
      responseTime: responseTime,
      decisions: guarded.decisions,
    );
  }

  _RankRun _guardAndRank(List<TavilySearchResult> results, SearchPlan plan) {
    final strict = <ScoredSearchResult>[
      for (final result in results)
        ScoredSearchResult(
          result: result,
          decision: _guard.evaluate(result: result, plan: plan),
        ),
    ];
    var decisions = strict
        .map((s) => _decisionDetail(s.result, s.decision))
        .toList();
    var ranked = _ranker.rank(strict);
    if (ranked.length >= 2) return _RankRun(ranked, decisions);

    // Second chance: same guard with a relaxed floor. Unrelated results still
    // fail the entity/headline overlap test; this only rescues borderline
    // local coverage.
    final strictUrls = {
      for (final s in strict)
        if (s.decision.keep) SearchResultRanker.canonicalUrl(s.result.url),
    };
    final relaxed = <ScoredSearchResult>[
      for (final result in results)
        if (!strictUrls.contains(SearchResultRanker.canonicalUrl(result.url)))
          ScoredSearchResult(
            result: result,
            decision: _guard.evaluate(
              result: result,
              plan: plan,
              minScore: AppConstants.tavilyRelaxedMinScore,
              relaxed: true,
            ),
          ),
    ];
    decisions = [
      ...decisions,
      ...relaxed.map((s) => _decisionDetail(s.result, s.decision)),
    ];
    ranked = _ranker.rank([...strict, ...relaxed]);
    return _RankRun(ranked, decisions);
  }

  SearchDecisionDetail _decisionDetail(
    TavilySearchResult result,
    SearchGuardDecision decision,
  ) {
    return SearchDecisionDetail(
      title: _truncate(
        result.title.trim().isEmpty ? result.url : result.title,
        90,
      ),
      keep: decision.keep,
      reason: decision.reason,
      score: result.score,
      relevance: decision.relevance,
    );
  }

  Future<List<ResearchSource>> _extractThinSources(
    List<ResearchSource> sources, {
    required String query,
    required String intent,
    CancelToken? cancelToken,
  }) async {
    if (sources.isEmpty) return sources;
    if (intent != 'result' && intent != 'stats') return sources;
    if (sources.any((s) => RegExp(r'\d').hasMatch(s.snippet))) return sources;

    final targets = sources.take(2).toList();
    final extracted = await Future.wait(
      targets.map((source) async {
        try {
          final result = await _searchRepo
              .extract(source.url, query: query, cancelToken: cancelToken)
              .timeout(const Duration(seconds: 12));
          return MapEntry(source.url, result.dataOrNull ?? '');
        } catch (_) {
          return MapEntry(source.url, '');
        }
      }),
    );
    final byUrl = {for (final e in extracted) e.key: e.value};
    return [
      for (final source in sources)
        if ((byUrl[source.url] ?? '').trim().length > source.snippet.length)
          ResearchSource(
            title: source.title,
            url: source.url,
            snippet: _truncate(byUrl[source.url]!.trim(), 900),
            outlet: source.outlet,
            publishedDate: source.publishedDate,
            score: source.score,
          )
        else
          source,
    ];
  }

  String _compose({
    required String originalContent,
    required List<ResearchSource> sources,
    required bool isUrl,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      isUrl ? 'ORIGINAL ARTICLE:' : 'ORIGINAL ARTICLE / POST CONTENT:',
    );
    buf.writeln(originalContent);
    buf.writeln('');
    buf.writeln('---');
    buf.writeln('REAL-TIME RESEARCH CONTEXT (web search):');
    buf.writeln(
      'Use only facts explicitly present below. Prefer the newest source when '
      'facts conflict. Never use a URL or domain as source.label.',
    );
    buf.writeln('');
    for (var i = 0; i < sources.length; i++) {
      final s = sources[i];
      final outlet = s.outlet.trim().isNotEmpty
          ? s.outlet.trim()
          : 'Unknown outlet';
      buf.writeln(
        'S${i + 1} | $outlet${s.publishedDate != null ? ' | ${s.publishedDate}' : ''}',
      );
      buf.writeln('Title: ${s.title}');
      buf.writeln('URL (INTERNAL ONLY, never use as source.label): ${s.url}');
      buf.writeln(s.snippet);
      buf.writeln('');
    }
    buf.writeln('EDITORIAL GUIDELINES FOR RESEARCH CONTEXT:');
    buf.writeln(
      '1. Incorporate concrete supporting facts, season stats, milestones, or '
      'head-to-head records from the research above to substantiate the post.',
    );
    buf.writeln(
      '2. STRICTLY FORBIDDEN: Do not add obvious commentary, superficial '
      'verdicts, or meaningless platitudes.',
    );
    buf.writeln(
      '3. Preserve every statistic, score, date, and proper noun from the '
      'original content unless the user explicitly asks to remove it.',
    );
    buf.writeln(
      '4. Focus 100% on high-value facts, figures, and verified details.',
    );
    return buf.toString();
  }

  /// Short system-prompt digest: sentences that actually carry numbers/dates.
  String _buildDigest(List<ResearchSource> sources) {
    final picked = <String>[];
    for (final source in sources) {
      final sentences = source.snippet
          .replaceAll(RegExp(r'\s+'), ' ')
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().length > 20)
          .where((s) => RegExp(r'\d').hasMatch(s))
          .take(2);
      for (final sentence in sentences) {
        picked.add(
          '${sentence.trim()}${source.outlet.trim().isNotEmpty ? ' (${source.outlet.trim()})' : ''}',
        );
        if (picked.join(' ').length >= AppConstants.tavilyDigestMaxChars) break;
      }
      if (picked.join(' ').length >= AppConstants.tavilyDigestMaxChars) break;
    }
    if (picked.isEmpty) {
      for (final source in sources.take(2)) {
        picked.add(_truncate(source.snippet, 240));
      }
    }
    return _truncate(picked.join(' '), AppConstants.tavilyDigestMaxChars);
  }

  EnrichmentResult _plain(
    String content,
    ResearchStatus status,
    String message, {
    String? query,
    String? intent,
    String? topic,
    int resultCount = 0,
    int credits = 0,
    String? failureKind,
    List<SearchDecisionDetail> decisions = const [],
    String? requestId,
    double? responseTime,
  }) {
    return EnrichmentResult(
      content: content,
      sources: const [],
      status: status,
      message: message,
      query: query,
      diagnostic: SearchDiagnosticEntry(
        at: DateTime.now(),
        status: status,
        query: query ?? '',
        intent: intent ?? '',
        topic: topic ?? '',
        resultCount: resultCount,
        credits: credits,
        message: message,
        failureKind: failureKind,
        decisions: decisions,
        requestId: requestId,
        responseTime: responseTime,
      ),
    );
  }

  String _truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max).trim()}…';
}

class _ResearchRun {
  const _ResearchRun({
    required this.sources,
    required this.credits,
    this.resultCount = 0,
    this.decisions = const [],
    this.requestId,
    this.responseTime,
    this.failure,
  });

  final List<ResearchSource> sources;
  final int credits;
  final int resultCount;
  final List<SearchDecisionDetail> decisions;
  final String? requestId;
  final double? responseTime;
  final Failure? failure;
}

class _RankRun {
  const _RankRun(this.sources, this.decisions);

  final List<ResearchSource> sources;
  final List<SearchDecisionDetail> decisions;
}
