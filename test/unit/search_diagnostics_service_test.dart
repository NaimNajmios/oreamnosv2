import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/search_diagnostics_service.dart';
import 'package:oreamnos/domain/models/research_context.dart';

void main() {
  SearchDiagnosticEntry entry(
    String query, {
    ResearchStatus status = ResearchStatus.ok,
  }) {
    return SearchDiagnosticEntry(
      at: DateTime(2026, 11, 28, 10, 30),
      status: status,
      query: query,
      intent: 'result',
      topic: 'general',
      resultCount: 4,
      keptCount: 2,
      credits: 1,
      message: '2 relevant source(s)',
      decisions: const [
        SearchDecisionDetail(
          title: 'JDT beat Selangor',
          keep: true,
          reason: 'relevant',
          score: 0.9,
        ),
      ],
    );
  }

  test('caps the ring and emits snapshots', () async {
    final service = SearchDiagnosticsService();
    final emissions = <int>[];
    final sub = service.stream.listen(
      (entries) => emissions.add(entries.length),
    );
    addTearDown(sub.cancel);

    for (var i = 0; i < SearchDiagnosticsService.maxEntries + 5; i++) {
      service.record(entry('query $i'));
    }

    expect(service.snapshot.length, SearchDiagnosticsService.maxEntries);
    expect(service.snapshot.first.query, 'query 5');
    expect(
      service.snapshot.last.query,
      'query ${SearchDiagnosticsService.maxEntries + 4}',
    );
    await Future<void>.delayed(Duration.zero);
    expect(emissions.length, SearchDiagnosticsService.maxEntries + 5);
  });

  test('summary is redacted and ordered newest first', () {
    final service = SearchDiagnosticsService()
      ..record(entry('first'))
      ..record(entry('second', status: ResearchStatus.failed));
    final summary = service.buildSummary();

    expect(summary, contains('Web search diagnostics'));
    expect(summary.indexOf('second'), lessThan(summary.indexOf('first')));
    expect(summary, contains('failed'));
    expect(summary, contains('KEEP'));
    expect(summary, isNot(contains('tvly-')));
  });

  test('clear empties the ring and notifies listeners', () async {
    final service = SearchDiagnosticsService()..record(entry('one'));
    final emissions = <int>[];
    final sub = service.stream.listen(
      (entries) => emissions.add(entries.length),
    );
    addTearDown(sub.cancel);

    service.clear();
    await Future<void>.delayed(Duration.zero);

    expect(service.snapshot, isEmpty);
    expect(emissions, contains(0));
  });
}
