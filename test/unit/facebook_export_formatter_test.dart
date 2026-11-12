import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/facebook_export_formatter.dart';
import 'package:oreamnos/domain/models/facebook_page_insights.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';

FacebookPostRecord _record({
  String id = 'r1',
  String snippet = 'Matchday',
  int? reactions,
  int? comments,
  int? shares,
  int? uniqueViewers,
  bool isStoryOnly = false,
  DateTime? timestamp,
}) => FacebookPostRecord(
  id: id,
  postId: 'post_$id',
  snippet: snippet,
  message: 'Full caption',
  timestamp: timestamp ?? DateTime(2026, 11, 10, 20),
  hasImage: true,
  permalink: isStoryOnly ? '' : 'https://facebook.com/post_$id',
  status: FacebookPostStatus.published,
  pageId: 'page-1',
  pageName: 'JDT',
  reactions: reactions,
  comments: comments,
  shares: shares,
  uniqueViewers: uniqueViewers,
  isStoryOnly: isStoryOnly,
);

void main() {
  group('FacebookExportFormatter', () {
    test('escapes commas, quotes and newlines per RFC 4180', () {
      final csv = FacebookExportFormatter.buildCsv([
        _record(snippet: 'Derby, "must win"\nnext line'),
      ]);

      expect(csv, contains('"Derby, ""must win""\nnext line"'));
    });

    test('null metrics render empty instead of zero', () {
      final csv = FacebookExportFormatter.buildCsv([_record()]);
      final row = csv.split('\n')[1].split(',');
      // reactions/comments/shares/unique_viewers/impressions are null.
      expect(row[9], '');
      expect(row[10], '');
      expect(row[11], '');
      expect(row[12], '');
      expect(row[13], '');
    });

    test('story-only records keep the flag and the empty permalink', () {
      final csv = FacebookExportFormatter.buildCsv([
        _record(isStoryOnly: true),
      ]);
      final row = csv.split('\n')[1].split(',');
      expect(row[1], 'published');
      expect(row[8], 'true');
      expect(row[14], '');
    });

    test('records are newest first', () {
      final csv = FacebookExportFormatter.buildCsv([
        _record(id: 'old', timestamp: DateTime(2026, 1, 1)),
        _record(id: 'new', timestamp: DateTime(2026, 11, 1)),
      ]);
      final rows = csv.split('\n');
      expect(rows[1].startsWith('new'), isTrue);
      expect(rows[2].startsWith('old'), isTrue);
    });

    test('optional performance block totals the cached insights', () {
      final csv = FacebookExportFormatter.buildCsv(
        [_record()],
        insights: FacebookPageInsights(
          pageId: 'page-1',
          fetchedAt: DateTime(2026, 11, 11),
          points: [
            PageInsightPoint(
              day: DateTime(2026, 11, 10),
              mediaViews: 5,
              follows: 3,
              engagements: 2,
            ),
          ],
        ),
      );
      final rows = csv.split('\n');
      expect(rows, contains('page_media_views,page_follows,page_engagements'));
      expect(rows, contains('5,3,2'));
    });

    test('JSON round-trips records and includes no secrets', () {
      final json = FacebookExportFormatter.buildJson([_record()]);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['records'], hasLength(1));
      expect(decoded['exportedAt'], isNotNull);
      expect(json, isNot(contains('access_token')));
      expect(json, isNot(contains('Bearer ')));
    });
  });
}
