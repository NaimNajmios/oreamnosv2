import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';

/// Injectable-clock alias (function types confuse injectable_generator).
typedef DailyUsageClock = DateTime Function();

/// Per-model quota entry for the DAILY QUOTA card.
class DailyQuota {
  const DailyQuota({
    required this.modelId,
    required this.requestsToday,
    required this.budget,
  });

  final String modelId;
  final int requestsToday;
  final int budget;

  double get fraction {
    if (budget <= 0) return 0;
    return (requestsToday / budget).clamp(0.0, 1.0);
  }

  /// ≥ `AppConstants.dailyQuotaWarnThreshold` → amber, at/over budget → red.
  bool get isWarning =>
      budget > 0 &&
      requestsToday >= (budget * AppConstants.dailyQuotaWarnThreshold).ceil();
  bool get isExhausted => budget > 0 && requestsToday >= budget;
}

/// Today's request count for one provider/model pair.
///
/// [budget] is null for providers whose daily limit the app does not know
/// (everything except the Gemini free tier). A null budget must render as a
/// count, never as "0 of something".
class ProviderQuota {
  const ProviderQuota({
    required this.providerId,
    required this.modelId,
    required this.requestsToday,
    required this.budget,
  });

  final String providerId;
  final String modelId;
  final int requestsToday;
  final int? budget;

  bool get hasBudget => budget != null && budget! > 0;
}

/// Daily (RPD-style) request counter for quota-budget visibility.
///
/// `UsageService` caps its history at 50 entries, so daily counts cannot be
/// derived from request logs. This service instead persists a compact
/// per-day counter map in SharedPreferences:
///
/// ```
/// { "<pacificDayKey>": { "<provider>:<model>": count } }
/// ```
///
/// Days roll over at midnight Pacific (Google's actual RPD reset) via a
/// dependency-free US-DST day-key helper. Counts include *all* attempts
/// (successes and failures) — 429-burned requests count against the
/// provider window too. Counts are device-local estimates: Google's real
/// quota is per project and may include other keys (AI Studio, etc.).
@lazySingleton
class DailyUsageService {
  DailyUsageService(this._prefs, {@ignoreParam DailyUsageClock? nowOverride})
    : _now = nowOverride ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const String _keyStore = 'daily_usage_v1';

  /// Days of history kept in the store: today plus the six before it. The
  /// widget's "average per day" line reads this window, so it has to be wider
  /// than the old today+yesterday prune.
  static const int historyDays = 7;

  /// Known free-tier requests-per-day budgets (ESTIMATES — verify current
  /// figures in Google AI Studio). Prefix-matched against the model id so
  /// dated variants (e.g. `-preview`) map too.
  static const List<MapEntry<String, int>> _budgetRules = [
    MapEntry('gemini-2.0-flash-lite', 1500),
    MapEntry('gemini-2.0-flash', 1500),
    MapEntry('gemini-2.5-flash-lite', 1000),
    MapEntry('gemini-2.5-flash', 1000),
  ];

  /// Free-tier budget for [modelId], conservative default for unknowns.
  static int budgetForModel(String? modelId) {
    final id = (modelId ?? '').trim().toLowerCase();
    if (id.isEmpty) return AppConstants.defaultDailyQuota;
    for (final rule in _budgetRules) {
      if (id.contains(rule.key) ||
          id == 'models/${rule.key}' ||
          id.startsWith('models/${rule.key}')) {
        return rule.value;
      }
    }
    return AppConstants.defaultDailyQuota;
  }

  /// Daily budget for a provider/model pair, or null when the app only knows
  /// Gemini's free tier. Groq, OpenRouter and Cerebras limits depend on the
  /// user's own account tier, so guessing one would be a lie on the home
  /// screen.
  static int? budgetForProviderModel(String providerId, String? modelId) {
    final provider = providerId.trim().toLowerCase();
    if (provider != 'gemini') return null;
    return budgetForModel(modelId);
  }

  Map<String, Map<String, int>> _load() {
    final raw = _prefs.getString(_keyStore);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          k,
          (v as Map<String, dynamic>).map(
            (pk, pv) => MapEntry(pk, (pv as num).toInt()),
          ),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(Map<String, Map<String, int>> store) async {
    try {
      await _prefs.setString(_keyStore, jsonEncode(store));
    } catch (_) {}
  }

  /// Increment the counter for one billable attempt. Called from
  /// `UsageService.logUsage` — the single funnel for all provider attempts.
  Future<void> recordRequest(String providerId, String? modelName) async {
    // Vision pseudo-provider is not quota-counted per model.
    if (providerId.trim().toLowerCase() == 'vision') return;
    final dayKey = pacificDayKey(_now());
    final store = _load()..removeWhere((k, _) => !_isRetainedDayKey(k, dayKey));
    final bucket = store[dayKey] ?? {};
    final modelKey =
        '${providerId.trim().toLowerCase()}:'
        '${(modelName ?? '').trim().toLowerCase()}';
    bucket[modelKey] = (bucket[modelKey] ?? 0) + 1;
    store[dayKey] = bucket;
    await _save(store);
  }

  /// Today's counts for [providerId], one entry per model that ran.
  ///
  /// [providerId] is matched case-insensitively against the `provider:model`
  /// keys written by [recordRequest].
  List<ProviderQuota> todayQuotaFor(String providerId) {
    final target = providerId.trim().toLowerCase();
    final dayKey = pacificDayKey(_now());
    final bucket = _load()[dayKey] ?? const {};
    final byModel = <String, int>{};
    for (final entry in bucket.entries) {
      final parts = entry.key.split(':');
      if (parts.isEmpty || parts.first != target) continue;
      final modelId = parts.length > 1 ? parts.sublist(1).join(':') : '';
      byModel[modelId] = (byModel[modelId] ?? 0) + entry.value;
    }
    final ids = byModel.keys.toList()
      ..sort((a, b) => byModel[b]!.compareTo(byModel[a]!));
    return [
      for (final id in ids)
        ProviderQuota(
          providerId: target,
          modelId: id.isEmpty ? 'unknown' : id,
          requestsToday: byModel[id]!,
          budget: budgetForProviderModel(target, id),
        ),
    ];
  }

  /// Every provider that ran today, one entry per model, busiest first.
  List<ProviderQuota> todayQuotaForAll() {
    final dayKey = pacificDayKey(_now());
    final bucket = _load()[dayKey] ?? const {};
    final providers = <String>{};
    for (final key in bucket.keys) {
      final provider = key.split(':').first;
      if (provider.isNotEmpty) providers.add(provider);
    }
    final all = <ProviderQuota>[
      for (final provider in providers) ...todayQuotaFor(provider),
    ]..sort((a, b) => b.requestsToday.compareTo(a.requestsToday));
    return all;
  }

  /// True when [providerId] recorded a request today. Null checks every
  /// provider.
  bool hasActivityToday([String? providerId]) {
    final dayKey = pacificDayKey(_now());
    final bucket = _load()[dayKey] ?? const {};
    if (providerId == null) {
      return bucket.values.any((count) => count > 0);
    }
    final prefix = '${providerId.trim().toLowerCase()}:';
    return bucket.keys.any((key) => key.startsWith(prefix) && bucket[key]! > 0);
  }

  /// Today's Gemini (provider `gemini`) counts grouped by model.
  List<DailyQuota> todayGeminiQuota() {
    return [
      for (final quota in todayQuotaFor('gemini'))
        DailyQuota(
          modelId: quota.modelId,
          requestsToday: quota.requestsToday,
          budget: quota.budget ?? budgetForModel(quota.modelId),
        ),
    ];
  }

  /// True when any Gemini request was recorded today (drives card visibility).
  bool hasGeminiActivityToday() => hasActivityToday('gemini');

  /// Per-model request counts over the retained window, oldest day first.
  ///
  /// Days with no activity for a model are omitted rather than reported as
  /// zero: a week away from the app must not drag the widget's "avg / day"
  /// line down. Model keys match [todayQuotaFor] (`unknown` for a null model
  /// name).
  Map<String, List<int>> quotaHistoryFor(
    String providerId, {
    int days = historyDays,
  }) {
    final target = providerId.trim().toLowerCase();
    final todayKey = pacificDayKey(_now());
    final cutoff = _cutoffDayKey(todayKey, days);
    final store = _load();
    final dayKeys =
        store.keys
            .where(
              (key) =>
                  key.compareTo(cutoff) >= 0 && key.compareTo(todayKey) <= 0,
            )
            .toList()
          ..sort();
    final byModel = <String, List<int>>{};
    for (final dayKey in dayKeys) {
      final bucket = store[dayKey] ?? const {};
      for (final entry in bucket.entries) {
        final parts = entry.key.split(':');
        if (parts.isEmpty || parts.first != target) continue;
        final modelId = parts.length > 1 ? parts.sublist(1).join(':') : '';
        final resolved = modelId.isEmpty ? 'unknown' : modelId;
        if (entry.value <= 0) continue;
        (byModel[resolved] ??= <int>[]).add(entry.value);
      }
    }
    return byModel;
  }

  Map<String, List<int>> geminiQuotaHistory({int days = historyDays}) =>
      quotaHistoryFor('gemini', days: days);

  /// Mean requests per active day over the retained window for one model.
  /// Null when the model has no activity in that window.
  int? averageFor(String providerId, String modelId) {
    final target = _normalizeModel(modelId);
    for (final entry in quotaHistoryFor(providerId).entries) {
      if (_normalizeModel(entry.key) != target) continue;
      final counts = entry.value.where((value) => value > 0).toList();
      if (counts.isEmpty) return null;
      final total = counts.fold<int>(0, (sum, value) => sum + value);
      return (total / counts.length).round();
    }
    return null;
  }

  static String _normalizeModel(String? modelId) {
    var value = (modelId ?? '').trim().toLowerCase();
    if (value.startsWith('models/')) {
      value = value.substring('models/'.length);
    }
    return value;
  }

  /// Clears every local daily-quota counter. Provider-side RPD windows are not
  /// affected; this only resets the device-local estimate shown in Usage.
  Future<void> clearAll() async {
    try {
      await _prefs.remove(_keyStore);
    } catch (_) {
      // Clearing must never crash the screen; a failed remove leaves the
      // counters intact, which the UI will show again on next load.
    }
  }

  /// Keep today plus the previous [historyDays] - 1 days.
  bool _isRetainedDayKey(String key, String todayKey) {
    return key.compareTo(_cutoffDayKey(todayKey, historyDays)) >= 0 &&
        key.compareTo(todayKey) <= 0;
  }

  /// `yyyy-MM-dd` for the oldest retained day. Day keys sort
  /// lexicographically, so string comparison is enough.
  static String _cutoffDayKey(String todayKey, int days) {
    final parts = todayKey.split('-');
    if (parts.length != 3) return todayKey;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return todayKey;
    final cutoff = DateTime(
      year,
      month,
      day,
    ).subtract(Duration(days: (days - 1).clamp(0, 365)));
    return '${cutoff.year.toString().padLeft(4, '0')}-'
        '${cutoff.month.toString().padLeft(2, '0')}-'
        '${cutoff.day.toString().padLeft(2, '0')}';
  }

  Duration timeUntilPacificReset() {
    final nowUtc = _now().toUtc();
    final todayKey = pacificDayKeyNowUtc(nowUtc);
    // Hourly probe, then binary-refine to the minute.
    for (var minutes = 60; minutes <= 26 * 60; minutes += 60) {
      final candidate = nowUtc.add(Duration(minutes: minutes));
      if (pacificDayKeyNowUtc(candidate) != todayKey) {
        var low = Duration(minutes: minutes - 60);
        var high = Duration(minutes: minutes);
        while (high - low > const Duration(minutes: 1)) {
          final mid = Duration(
            milliseconds: ((low.inMilliseconds + high.inMilliseconds) / 2)
                .round(),
          );
          final probe = nowUtc.add(mid);
          if (pacificDayKeyNowUtc(probe) != todayKey) {
            high = mid;
          } else {
            low = mid;
          }
        }
        return high;
      }
    }
    return const Duration(hours: 24);
  }

  // --- Pacific day-key helpers (US DST rules, dependency-free) ---

  /// Formats a [DateTime] (UTC) into `yyyy-MM-dd` in America/Los_Angeles.
  static String pacificDayKeyNowUtc(DateTime utc) {
    final offset = _pacificOffsetUtc(utc);
    final pacific = utc.add(offset);
    return '${pacific.year.toString().padLeft(4, '0')}-'
        '${pacific.month.toString().padLeft(2, '0')}-'
        '${pacific.day.toString().padLeft(2, '0')}';
  }

  /// Convenience: accepts any local-time [DateTime].
  static String pacificDayKey(DateTime anyTime) =>
      pacificDayKeyNowUtc(anyTime.toUtc());

  /// UTC offset of America/Los_Angeles at the given UTC instant.
  /// Standard time: -8h. DST: -7h, active from the second Sunday of March
  /// 2:00 AM Pacific to the first Sunday of November 2:00 AM Pacific.
  static Duration _pacificOffsetUtc(DateTime utc) {
    final year = utc.year;
    final dstStartUtc = _nthSundayUTC(
      year,
      3,
      2,
    ).add(const Duration(hours: 10)); // 02:00 PST = 10:00 UTC
    final dstEndUtc = _nthSundayUTC(
      year,
      11,
      1,
    ).add(const Duration(hours: 9)); // 02:00 PDT = 09:00 UTC
    final isDst = utc.isAfter(dstStartUtc) && utc.isBefore(dstEndUtc);
    return isDst ? const Duration(hours: -7) : const Duration(hours: -8);
  }

  /// UTC instant of 00:00 UTC on the [n]th Sunday of [month].
  static DateTime _nthSundayUTC(int year, int month, int n) {
    final first = DateTime.utc(year, month, 1);
    final firstWeekday = first.weekday; // 1 = Monday … 7 = Sunday
    final firstSundayDay = firstWeekday == DateTime.sunday
        ? 1
        : 1 + (7 - firstWeekday);
    return DateTime.utc(year, month, firstSundayDay + (n - 1) * 7);
  }
}
