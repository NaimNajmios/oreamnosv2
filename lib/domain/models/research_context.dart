import 'dart:async';

/// Research-mode domain types.
///
/// Research is strictly opt-in: [ResearchStatus.off] is the default and the
/// only state that guarantees zero Tavily calls.
enum ResearchStatus {
  /// Toggle is off — no network call is made.
  off,

  /// Search in flight.
  searching,

  /// At least one relevant source reached the prompt.
  ok,

  /// Tavily answered but nothing passed the relevance guard.
  empty,

  /// Network/auth/plan/parse failure.
  failed,

  /// No Tavily key stored.
  unconfigured,

  /// The user stopped generation while research was running.
  cancelled,
}

/// One source that survived ranking and reached the prompt.
class ResearchSource {
  const ResearchSource({
    required this.title,
    required this.url,
    required this.snippet,
    this.outlet = '',
    this.publishedDate,
    this.score = 0,
  });

  final String title;
  final String url;
  final String snippet;
  final String outlet;
  final String? publishedDate;
  final double score;

  String get domain => Uri.tryParse(url)?.host ?? '';

  /// Label shown in the UI. Never the URL/domain (see `SourcePolicy`).
  String get displayLabel => outlet.trim().isNotEmpty
      ? outlet.trim()
      : (domain.isEmpty ? url : domain);

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'snippet': snippet,
    'outlet': outlet,
    'published_date': publishedDate,
    'score': score,
  };
}

/// Why one Tavily result was kept or dropped. Titles are truncated and no
/// response bodies are stored, so this is safe to paste into a bug report.
class SearchDecisionDetail {
  const SearchDecisionDetail({
    required this.title,
    required this.keep,
    required this.reason,
    required this.score,
    this.relevance = 0,
  });

  final String title;
  final bool keep;
  final String reason;
  final double score;
  final double relevance;

  Map<String, dynamic> toJson() => {
    'title': title,
    'keep': keep,
    'reason': reason,
    'score': score,
    'relevance': relevance,
  };
}

/// One research run as shown on the diagnostics screen. Never contains an API
/// key, response body, or source snippet.
class SearchDiagnosticEntry {
  const SearchDiagnosticEntry({
    required this.at,
    required this.status,
    required this.query,
    this.intent = '',
    this.topic = '',
    this.resultCount = 0,
    this.keptCount = 0,
    this.credits = 0,
    this.message,
    this.failureKind,
    this.requestId,
    this.responseTime,
    this.decisions = const [],
    this.planner = 'heuristic',
  });

  final DateTime at;
  final ResearchStatus status;
  final String query;
  final String intent;
  final String topic;
  final int resultCount;
  final int keptCount;
  final int credits;
  final String? message;
  final String? failureKind;
  final String? requestId;
  final double? responseTime;
  final List<SearchDecisionDetail> decisions;

  /// `groq` when the optional AI planner produced the queries, otherwise
  /// `heuristic`. Useful when checking why a run searched a given phrase.
  final String planner;

  SearchDiagnosticEntry copyWith({
    ResearchStatus? status,
    int? resultCount,
    int? keptCount,
    int? credits,
    String? message,
    String? failureKind,
    String? requestId,
    double? responseTime,
    List<SearchDecisionDetail>? decisions,
    String? planner,
  }) {
    return SearchDiagnosticEntry(
      at: at,
      status: status ?? this.status,
      query: query,
      intent: intent,
      topic: topic,
      resultCount: resultCount ?? this.resultCount,
      keptCount: keptCount ?? this.keptCount,
      credits: credits ?? this.credits,
      message: message ?? this.message,
      failureKind: failureKind ?? this.failureKind,
      requestId: requestId ?? this.requestId,
      responseTime: responseTime ?? this.responseTime,
      decisions: decisions ?? this.decisions,
      planner: planner ?? this.planner,
    );
  }

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'status': status.name,
    'query': query,
    'intent': intent,
    'topic': topic,
    'resultCount': resultCount,
    'keptCount': keptCount,
    'credits': credits,
    'message': message,
    'failureKind': failureKind,
    'requestId': requestId,
    'responseTime': responseTime,
    'planner': planner,
    'decisions': [for (final d in decisions) d.toJson()],
  };
}

/// Domain-facing sink so the use case stays independent of UI/data plumbing.
abstract class SearchDiagnosticsRecorder {
  const SearchDiagnosticsRecorder();

  void record(SearchDiagnosticEntry entry);

  List<SearchDiagnosticEntry> get snapshot => const [];

  Stream<List<SearchDiagnosticEntry>> get stream => const Stream.empty();

  void clear() {}

  String buildSummary() => '';
}

class NoopSearchDiagnosticsRecorder extends SearchDiagnosticsRecorder {
  const NoopSearchDiagnosticsRecorder();

  @override
  void record(SearchDiagnosticEntry entry) {}
}
