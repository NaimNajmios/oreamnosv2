import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/data/services/notification_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';

/// Thin seam over platform notifications so reminder logic is unit-testable.
abstract interface class FacebookReminderScheduler {
  Future<bool> requestPermission();
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String payload,
  });
  Future<void> cancel(int id);
}

class LocalFacebookReminderScheduler implements FacebookReminderScheduler {
  const LocalFacebookReminderScheduler();

  @override
  Future<bool> requestPermission() => NotificationService().requestPermission();

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String payload = 'facebook_scheduled_post',
  }) {
    return NotificationService().scheduleFacebookReminder(
      id: id,
      title: title,
      body: body,
      at: at,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => NotificationService().cancelNotification(id);
}

/// Keeps one local reminder per scheduled Page post, ten minutes before it
/// goes live. The notification text never contains the caption or a token.
@lazySingleton
class FacebookReminderService {
  FacebookReminderService(this._prefs, [FacebookReminderScheduler? scheduler])
    : _scheduler = scheduler ?? const LocalFacebookReminderScheduler();

  static const Duration lead = Duration(minutes: 10);

  final SharedPreferences _prefs;
  final FacebookReminderScheduler _scheduler;

  bool _permissionChecked = false;

  bool get enabled =>
      _prefs.getBool(AppConstants.keyFacebookRemindersEnabled) ?? true;

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(AppConstants.keyFacebookRemindersEnabled, value);
    if (!value) await cancelAll();
  }

  /// Reconciles the persisted id map with [records]. Never throws: a denied
  /// permission or a platform failure must not break publishing.
  Future<void> sync(List<FacebookPostRecord> records) async {
    if (!enabled) return;
    try {
      if (!_permissionChecked) {
        _permissionChecked = true;
        final granted = await _scheduler.requestPermission();
        if (!granted) return;
      }
      final previous = _readIds();
      final next = <String, int>{};
      final now = DateTime.now();
      for (final record in records) {
        if (!record.isScheduled) continue;
        final at = record.scheduledAt;
        if (at == null) continue;
        final reminderAt = at.subtract(lead);
        if (!reminderAt.isAfter(now)) continue;
        final id = previous[record.id] ?? _allocateId(record.id, next.values);
        next[record.id] = id;
        await _scheduler.schedule(
          id: id,
          title: 'Post goes live soon',
          body: 'Scheduled for ${_formatTime(at)}',
          at: reminderAt,
        );
      }
      for (final entry in previous.entries) {
        if (!next.containsKey(entry.key)) {
          await _scheduler.cancel(entry.value);
        }
      }
      await _writeIds(next);
    } catch (_) {
      // Reminders are best-effort; publishing never depends on them.
    }
  }

  Future<void> cancelAll() async {
    final ids = _readIds();
    for (final id in ids.values) {
      try {
        await _scheduler.cancel(id);
      } catch (_) {}
    }
    await _writeIds(const {});
  }

  int _allocateId(String recordId, Iterable<int> taken) {
    final used = taken.toSet();
    var id = recordId.hashCode & 0x7fffffff;
    if (id == 0) id = 1;
    while (used.contains(id)) {
      id = (id + 1) & 0x7fffffff;
      if (id == 0) id = 1;
    }
    return id;
  }

  Map<String, int> _readIds() {
    try {
      final raw = _prefs.getString(AppConstants.keyFacebookReminderIds);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is num)
            entry.key.toString(): (entry.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeIds(Map<String, int> ids) async {
    await _prefs.setString(
      AppConstants.keyFacebookReminderIds,
      jsonEncode(ids),
    );
  }

  static String _formatTime(DateTime at) {
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    final suffix = at.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }
}
