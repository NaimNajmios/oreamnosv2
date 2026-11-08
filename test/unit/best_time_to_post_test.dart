import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/domain/services/best_time_to_post.dart';

FacebookPostRecord _record({
  required String id,
  required DateTime timestamp,
  int? reactions,
  int? comments,
  int? shares,
  FacebookPostStatus status = FacebookPostStatus.published,
}) {
  return FacebookPostRecord(
    id: id,
    postId: 'post_$id',
    snippet: 'Post $id',
    timestamp: timestamp,
    hasImage: false,
    permalink: 'https://facebook.com/post_$id',
    status: status,
    reactions: reactions,
    comments: comments,
    shares: shares,
  );
}

void main() {
  final now = DateTime(2026, 11, 8, 12); // Sunday noon, device-local.

  group('BestTimeToPost.compute', () {
    test('returns a confirmed slot when a weekday/hour repeats', () {
      final slots = BestTimeToPost.compute([
        _record(id: '0', timestamp: DateTime(2026, 10, 18, 10), reactions: 10),
        _record(id: '1', timestamp: DateTime(2026, 10, 25, 10), reactions: 20),
        _record(id: '2', timestamp: DateTime(2026, 11, 1, 10), reactions: 30),
        _record(id: '3', timestamp: DateTime(2026, 10, 29, 18), reactions: 5),
        _record(id: '4', timestamp: DateTime(2026, 11, 2, 18), reactions: 6),
      ], now: now);

      expect(slots, isNotEmpty);
      expect(slots.first.weekday, DateTime.sunday);
      expect(slots.first.hour, 10);
      expect(slots.first.sampleSize, 3);
      expect(slots.first.confidence, isTrue);
    });

    test('ignores scheduled, failed, and engagement-free posts', () {
      final slots = BestTimeToPost.compute([
        _record(
          id: 'scheduled',
          timestamp: now,
          reactions: 100,
          status: FacebookPostStatus.scheduled,
        ),
        _record(
          id: 'failed',
          timestamp: now,
          reactions: 100,
          status: FacebookPostStatus.failed,
        ),
        _record(id: 'no-engagement-1', timestamp: DateTime(2026, 10, 25, 9)),
        _record(id: 'no-engagement-2', timestamp: DateTime(2026, 11, 1, 9)),
      ], now: now);

      expect(slots, isEmpty);
    });

    test('needs at least two posts in the same bucket', () {
      final slots = BestTimeToPost.compute([
        _record(id: '1', timestamp: DateTime(2026, 10, 25, 10), reactions: 20),
        _record(id: '2', timestamp: DateTime(2026, 10, 26, 11), reactions: 30),
      ], now: now);

      expect(slots, isEmpty);
    });

    test('prefers more engagement and orders best first', () {
      final slots = BestTimeToPost.compute([
        _record(id: '1', timestamp: DateTime(2026, 10, 25, 10), reactions: 2),
        _record(id: '2', timestamp: DateTime(2026, 11, 1, 10), reactions: 3),
        _record(id: '3', timestamp: DateTime(2026, 10, 26, 11), comments: 40),
        _record(id: '4', timestamp: DateTime(2026, 11, 2, 11), comments: 50),
      ], now: now);

      expect(slots.first.hour, 11);
      expect(slots.first.score, greaterThan(slots[1].score));
    });

    test('emptyReason explains when history is too thin', () {
      final reason = BestTimeToPost.emptyReason([
        _record(id: '1', timestamp: DateTime(2026, 10, 25, 10), reactions: 20),
      ]);

      expect(reason, contains('more published posts'));
    });
  });

  group('BestTimeToPost.nextOccurrence', () {
    test('returns the next matching weekday at the bucket hour', () {
      final slot = BestTimeToPost.compute([
        _record(id: '1', timestamp: DateTime(2026, 10, 25, 10), reactions: 20),
        _record(id: '2', timestamp: DateTime(2026, 11, 1, 10), reactions: 30),
      ], now: now).first;

      final next = BestTimeToPost.nextOccurrence(slot, now: now);

      expect(next.weekday, DateTime.sunday);
      expect(next.hour, 10);
      expect(next.isAfter(now), isTrue);
      expect(next, DateTime(2026, 11, 15, 10));
    });

    test('rolls forward a full week when today is too close', () {
      final slot = BestTimeToPost.compute([
        _record(id: '1', timestamp: DateTime(2026, 10, 25, 10), reactions: 20),
        _record(id: '2', timestamp: DateTime(2026, 11, 1, 10), reactions: 30),
      ], now: now).first;

      final next = BestTimeToPost.nextOccurrence(
        slot,
        now: DateTime(2026, 11, 8, 10).subtract(const Duration(minutes: 5)),
      );

      expect(next.isAfter(DateTime(2026, 11, 8, 10)), isTrue);
      expect(next.difference(DateTime(2026, 11, 8, 10)).inDays, 7);
    });
  });
}
