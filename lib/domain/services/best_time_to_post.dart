import 'dart:math' as math;

import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/domain/models/posting_time_slot.dart';

/// Deterministic, local "best time to post" heuristic.
///
/// There is no Meta API for this. The score uses the Page's own published
/// history: comments and shares weigh more than reactions, and older posts
/// decay with a 21-day half-life. No network, no model, no AI.
class BestTimeToPost {
  static const int minBucketSample = 2;
  static const int confidentSample = 3;
  static const double _halfLifeDays = 21;

  /// Returns up to [limit] slots, best first. Empty when there is not enough
  /// engagement history — the UI must say so instead of inventing a time.
  static List<PostingTimeSlot> compute(
    List<FacebookPostRecord> records, {
    DateTime? now,
    int limit = 3,
  }) {
    final reference = now ?? DateTime.now();
    final buckets = <int, _Bucket>{};

    for (final record in records) {
      if (!record.isPublished) continue;
      final hasEngagement =
          record.reactions != null ||
          record.comments != null ||
          record.shares != null;
      if (!hasEngagement) continue;
      final ageDays = reference.difference(record.timestamp).inHours / 24.0;
      if (ageDays < 0) continue;
      final weight = math.pow(0.5, ageDays / _halfLifeDays).toDouble();
      final key = record.timestamp.weekday * 24 + record.timestamp.hour;
      final bucket = buckets.putIfAbsent(key, _Bucket.new);
      bucket.weightedScore += record.engagementScore * weight;
      bucket.weight += weight;
      bucket.sampleSize += 1;
    }

    if (buckets.isEmpty) return const [];

    final slots = <PostingTimeSlot>[];
    for (final entry in buckets.entries) {
      final bucket = entry.value;
      if (bucket.sampleSize < minBucketSample) continue;
      final score = bucket.weight == 0
          ? 0.0
          : bucket.weightedScore / bucket.weight;
      slots.add(
        PostingTimeSlot(
          weekday: entry.key ~/ 24,
          hour: entry.key % 24,
          score: score,
          sampleSize: bucket.sampleSize,
          confidence: bucket.sampleSize >= confidentSample,
        ),
      );
    }

    slots.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.sampleSize.compareTo(a.sampleSize);
    });
    return slots.take(limit).toList(growable: false);
  }

  /// Next occurrence of [slot] in device-local time, at least 10 minutes
  /// ahead so Graph accepts the schedule.
  static DateTime nextOccurrence(
    PostingTimeSlot slot, {
    DateTime? now,
    Duration minLead = const Duration(minutes: 10),
  }) {
    final reference = now ?? DateTime.now();
    var daysAhead = (slot.weekday - reference.weekday) % 7;
    var candidate = DateTime(
      reference.year,
      reference.month,
      reference.day + daysAhead,
      slot.hour,
    );
    if (!candidate.isAfter(reference.add(minLead))) {
      daysAhead += 7;
      candidate = DateTime(
        reference.year,
        reference.month,
        reference.day + daysAhead,
        slot.hour,
      );
    }
    return candidate;
  }

  static String emptyReason(List<FacebookPostRecord> records) {
    final usable = records.where(
      (r) =>
          r.isPublished &&
          (r.reactions != null || r.comments != null || r.shares != null),
    );
    if (usable.length < minBucketSample) {
      return 'Add a few more published posts with engagement to unlock '
          'suggested times.';
    }
    return 'No single weekday/hour has enough posts yet. Try again after '
        'your next few posts.';
  }
}

class _Bucket {
  double weightedScore = 0;
  double weight = 0;
  int sampleSize = 0;
}
