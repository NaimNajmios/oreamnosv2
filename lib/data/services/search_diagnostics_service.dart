import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/models/research_context.dart';

/// In-memory ring of the last web-research runs.
///
/// Only query text, failure taxonomy and per-result keep/drop reasons are
/// retained. Snippets, response bodies and API keys are never stored here.
@LazySingleton(as: SearchDiagnosticsRecorder)
class SearchDiagnosticsService extends SearchDiagnosticsRecorder {
  static const int maxEntries = 30;

  final List<SearchDiagnosticEntry> _entries = [];
  final StreamController<List<SearchDiagnosticEntry>> _controller =
      StreamController<List<SearchDiagnosticEntry>>.broadcast();

  @override
  List<SearchDiagnosticEntry> get snapshot =>
      List<SearchDiagnosticEntry>.unmodifiable(_entries);

  @override
  Stream<List<SearchDiagnosticEntry>> get stream => _controller.stream;

  @override
  void record(SearchDiagnosticEntry entry) {
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    if (!_controller.isClosed) _controller.add(snapshot);
  }

  @override
  void clear() {
    _entries.clear();
    if (!_controller.isClosed) _controller.add(snapshot);
  }

  /// Redacted plain-text summary for pasting into a bug report.
  @override
  String buildSummary() {
    final buffer = StringBuffer()..writeln('Web search diagnostics');
    for (final entry in _entries.reversed) {
      buffer
        ..writeln(
          '${entry.at.toIso8601String()} ${entry.status.name} '
          'q="${entry.query}" intent=${entry.intent} topic=${entry.topic} '
          'results=${entry.resultCount} kept=${entry.keptCount} '
          'credits=${entry.credits}',
        )
        ..writeln(
          '  planner=${entry.planner} '
          'message=${entry.message ?? '-'} '
          'failure=${entry.failureKind ?? '-'} '
          'requestId=${entry.requestId ?? '-'} '
          'responseTime=${entry.responseTime ?? '-'}',
        );
      for (final d in entry.decisions) {
        buffer.writeln(
          '  ${d.keep ? 'KEEP' : 'DROP'} score=${d.score} '
          'relevance=${d.relevance} reason=${d.reason} title="${d.title}"',
        );
      }
    }
    return buffer.toString().trimRight();
  }
}
