import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/domain/services/best_time_to_post.dart';

FacebookPostRecord _record({
  required String id,
  required DateTime timestamp,
  int? reactions,
  int? comments,
  int? shares,
  int? uniqueViewers,
  int? impressions,
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
    uniqueViewers: uniqueViewers,
    impressions: impressions,
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

    test('reach-normalized engagement beats a high-reach raw winner', () {
      final slots = BestTimeToPost.compute([
        // Raw engagement 50 each, but spread over 1,000 viewers.
        _record(
          id: 'a1',
          timestamp: DateTime(2026, 10, 18, 10),
          reactions: 50,
          uniqueViewers: 1000,
        ),
        _record(
          id: 'a2',
          timestamp: DateTime(2026, 10, 25, 10),
          reactions: 50,
          uniqueViewers: 1000,
        ),
        // Smaller raw engagement, but far higher engagement rate.
        _record(
          id: 'b1',
          timestamp: DateTime(2026, 10, 19, 15),
          reactions: 20,
          uniqueViewers: 100,
        ),
        _record(
          id: 'b2',
          timestamp: DateTime(2026, 10, 26, 15),
          reactions: 20,
          uniqueViewers: 100,
        ),
      ], now: now);

      expect(slots.first.weekday, DateTime.monday);
      expect(slots.first.hour, 15);
      expect(slots.first.score, greaterThan(slots[1].score));
    });

    test('posts without reach fall back to raw engagement', () {
      final slots = BestTimeToPost.compute([
        _record(
          id: 'reach1',
          timestamp: DateTime(2026, 10, 18, 10),
          reactions: 5,
          impressions: 1000,
        ),
        _record(
          id: 'reach2',
          timestamp: DateTime(2026, 10, 25, 10),
          reactions: 5,
          impressions: 1000,
        ),
        _record(
          id: 'raw1',
          timestamp: DateTime(2026, 10, 19, 15),
          reactions: 10,
        ),
        _record(
          id: 'raw2',
          timestamp: DateTime(2026, 10, 26, 15),
          reactions: 10,
        ),
      ], now: now);

      expect(slots.first.hour, 15);
    });

    test('adjacent-hour smoothing blends neighbours on the same weekday', () {
      final slots = BestTimeToPost.compute([
        _record(
          id: '10a',
          timestamp: DateTime(2026, 10, 18, 10),
          reactions: 10,
        ),
        _record(
          id: '10b',
          timestamp: DateTime(2026, 10, 25, 10),
          reactions: 10,
        ),
        _record(
          id: '11a',
          timestamp: DateTime(2026, 10, 18, 11),
          reactions: 20,
        ),
        _record(
          id: '11b',
          timestamp: DateTime(2026, 10, 25, 11),
          reactions: 20,
        ),
        _record(
          id: '12a',
          timestamp: DateTime(2026, 10, 18, 12),
          reactions: 40,
        ),
        _record(
          id: '12b',
          timestamp: DateTime(2026, 10, 25, 12),
          reactions: 40,
        ),
      ], now: now);

      double score(int hour) =>
          slots.firstWhere((slot) => slot.hour == hour).score;

      expect(score(10), closeTo(12.5, 0.001));
      expect(score(11), closeTo(22.0, 0.001));
      expect(score(12), closeTo(35.0, 0.001));
    });

    test('confidence and sample size stay tied to the hour own history', () {
      final slots = BestTimeToPost.compute([
        _record(
          id: '10a',
          timestamp: DateTime(2026, 10, 18, 10),
          reactions: 10,
        ),
        _record(
          id: '10b',
          timestamp: DateTime(2026, 10, 25, 10),
          reactions: 10,
        ),
        _record(id: '10c', timestamp: DateTime(2026, 11, 1, 10), reactions: 10),
        _record(
          id: '11a',
          timestamp: DateTime(2026, 10, 18, 11),
          reactions: 20,
        ),
        _record(
          id: '11b',
          timestamp: DateTime(2026, 10, 25, 11),
          reactions: 20,
        ),
      ], now: now);

      final ten = slots.firstWhere((slot) => slot.hour == 10);
      final eleven = slots.firstWhere((slot) => slot.hour == 11);
      expect(ten.sampleSize, 3);
      expect(ten.confidence, isTrue);
      expect(eleven.sampleSize, 2);
      expect(eleven.confidence, isFalse);
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
