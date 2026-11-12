import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_calendar_view_model.dart';

FacebookPostRecord _record({
  required String id,
  required DateTime timestamp,
  DateTime? scheduledAt,
}) => FacebookPostRecord(
  id: id,
  postId: 'post_$id',
  snippet: 'Post $id',
  message: 'Post $id',
  timestamp: timestamp,
  hasImage: false,
  permalink: 'https://facebook.com/post_$id',
  status: scheduledAt == null
      ? FacebookPostStatus.published
      : FacebookPostStatus.scheduled,
  scheduledAt: scheduledAt,
  pageId: 'page-1',
);

void main() {
  group('facebookCalendarMonthGrid', () {
    test('is Monday-first with leading blanks', () {
      // 1 November 2026 is a Sunday.
      final grid = facebookCalendarMonthGrid(DateTime(2026, 11));
      expect(grid, hasLength(42));
      expect(grid.take(6), everyElement(isNull));
      expect(grid[6], DateTime(2026, 11, 1));
      expect(grid[6 + 29], DateTime(2026, 11, 30));
      expect(grid[36], isNull);
    });

    test('handles a leap February', () {
      // 1 February 2024 is a Thursday.
      final grid = facebookCalendarMonthGrid(DateTime(2024, 2));
      expect(grid.take(3), everyElement(isNull));
      expect(grid[3], DateTime(2024, 2, 1));
      expect(grid[3 + 28], DateTime(2024, 2, 29));
      expect(grid[3 + 29], isNull);
    });
  });

  group('facebookCalendarGroup', () {
    test(
      'groups scheduled posts by scheduled day and published by timestamp',
      () {
        final grouped = facebookCalendarGroup([
          _record(
            id: 's1',
            timestamp: DateTime(2026, 10, 1),
            scheduledAt: DateTime(2026, 11, 2, 21),
          ),
          _record(id: 'p1', timestamp: DateTime(2026, 11, 2, 9)),
          _record(id: 'p2', timestamp: DateTime(2026, 12, 1, 9)),
        ]);

        expect(grouped[DateTime(2026, 11, 2)], hasLength(2));
        expect(grouped[DateTime(2026, 12, 1)], hasLength(1));
        expect(grouped[DateTime(2026, 10, 1)], isNull);
      },
    );

    test('sorts a day by time', () {
      final grouped = facebookCalendarGroup([
        _record(id: 'late', timestamp: DateTime(2026, 11, 2, 21)),
        _record(id: 'early', timestamp: DateTime(2026, 11, 2, 8)),
      ]);
      expect(grouped[DateTime(2026, 11, 2)]!.map((r) => r.id), [
        'early',
        'late',
      ]);
    });
  });
}
