import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';

/// Local-midnight key for a day. Built from calendar fields (not UTC) so a
/// DST shift never collapses two days into one key.
DateTime facebookCalendarDayKey(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// 42-cell Monday-first grid for [month], with `null` leading/trailing blanks.
List<DateTime?> facebookCalendarMonthGrid(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final leading = (first.weekday - DateTime.monday) % 7;
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  return List<DateTime?>.generate(42, (index) {
    final day = index - leading + 1;
    if (day < 1 || day > daysInMonth) return null;
    return DateTime(month.year, month.month, day);
  });
}

/// The day a record belongs to: scheduled time for scheduled posts, publish
/// time otherwise.
DateTime facebookCalendarRecordDay(FacebookPostRecord record) {
  final at = record.isScheduled ? record.scheduledAt : record.timestamp;
  return facebookCalendarDayKey(at ?? record.timestamp);
}

Map<DateTime, List<FacebookPostRecord>> facebookCalendarGroup(
  List<FacebookPostRecord> records,
) {
  final grouped = <DateTime, List<FacebookPostRecord>>{};
  for (final record in records) {
    grouped
        .putIfAbsent(facebookCalendarRecordDay(record), () => [])
        .add(record);
  }
  for (final entry in grouped.values) {
    entry.sort((a, b) {
      final at = (a.scheduledAt ?? a.timestamp).compareTo(
        b.scheduledAt ?? b.timestamp,
      );
      return at;
    });
  }
  return grouped;
}

final facebookCalendarProvider =
    Provider<Map<DateTime, List<FacebookPostRecord>>>((ref) {
      return facebookCalendarGroup(ref.watch(facebookHistoryProvider));
    });
