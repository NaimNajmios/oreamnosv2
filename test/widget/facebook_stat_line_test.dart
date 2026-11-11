import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_stat_line.dart';

FacebookPostRecord _record({
  int? impressions,
  int? uniqueViewers,
  int? reactions,
  int? comments,
  int? shares,
  int? clicks,
}) {
  return FacebookPostRecord(
    id: 'id',
    postId: 'page_1',
    snippet: 'Snippet',
    timestamp: DateTime(2026, 11, 1),
    hasImage: false,
    permalink: 'https://www.facebook.com/page_1',
    impressions: impressions,
    uniqueViewers: uniqueViewers,
    reactions: reactions,
    comments: comments,
    shares: shares,
    clicks: clicks,
  );
}

void main() {
  group('facebookStatsFor', () {
    test('prefers unique viewers over legacy impressions', () {
      final stats = facebookStatsFor(
        _record(uniqueViewers: 1234, impressions: 9999, reactions: 12),
      );

      expect(stats.map((s) => s.label), ['Views', 'Reactions']);
      expect(stats.first.value, '1.2k');
    });

    test('falls back to impressions when unique viewers are absent', () {
      final stats = facebookStatsFor(_record(impressions: 1500));

      expect(stats.single.label, 'Views');
      expect(stats.single.value, '1.5k');
    });

    test('formats millions and small values', () {
      final stats = facebookStatsFor(
        _record(uniqueViewers: 2500000, comments: 7, shares: 0, clicks: 3),
      );

      expect(stats[0].value, '2.5m');
      expect(stats[1].value, '7');
      expect(stats[2].value, '0');
      expect(stats[3].value, '3');
    });

    test('returns an empty list when no metric exists', () {
      expect(facebookStatsFor(_record()), isEmpty);
    });
  });

  testWidgets('stat line exposes one semantics label without emoji glyphs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FacebookStatLine(
            stats: facebookStatsFor(
              _record(uniqueViewers: 12, reactions: 3, comments: 1),
            ),
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('👁'), findsNothing);
    final semantics = tester.getSemantics(find.byType(FacebookStatLine));
    expect(semantics.label, contains('Views 12'));
    expect(semantics.label, contains('Reactions 3'));
    expect(semantics.label, contains('Comments 1'));
  });
}
