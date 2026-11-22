import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/daily_usage_service.dart';

/// Persisted "cooling down" state written by [RateLimitGuard.recordCooldown].
///
/// A provider entry means: skip new generation attempts for this provider
/// until [untilMs]. Squeeze rules (see [RateLimitGuard.recordCooldown]).
class RateLimitGuardEntry {
  const RateLimitGuardEntry({required this.untilMs, required this.source});

  final int untilMs;
  final String source;

  @override
  String toString() =>
      'RateLimitGuardEntry(untilMs: $untilMs, source: $source)';
}

/// Tracks per-provider provider-side throttling as a persisted cooldown.
///
/// The policy separates the two 429 seam kinds Google reports on the free
/// tier:
///
///  - **RPM window** (`RetryInfo` delay ≤ [AppConstants.guardRpmSuspectThresholdMs]
///    or unparseable): the per-minute window is nearly closed, but it resets
///    within a minute — the cooldown stays in the window
///    ([guardRpmUntilFloorMs]…[guardRpmUntilCapMs]).
///  - **RPD exhaustion** (longer delays, e.g. "retry in 30+ min"): block until
///    the real daily reset ([DailyUsageService.timeUntilPacificReset], i.e.
///    Pacific-midnight) — never past it, so the next user request after the
///    reset is allowed again.
///
/// Entries persist in SharedPreferences so cool-downs survive app restarts.
@lazySingleton
class RateLimitGuard {
  RateLimitGuard(this._prefs, {@ignoreParam DailyUsageClock? now})
    : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DailyUsageClock _now;

  static const String _keyStore = 'rate_limit_v1';
  static const String _fieldUntilMs = 'untilMs';
  static const String _fieldSource = 'source';

  DailyUsageService? get _dailyService =>
      getIt.isRegistered<DailyUsageService>()
      ? getIt<DailyUsageService>()
      : null;

  bool isCoolingDown(AiProvider provider) =>
      _readUntilMs(provider) > _now().millisecondsSinceEpoch;

  Duration timeUntil(AiProvider provider) {
    final untilMs = _readUntilMs(provider);
    final ms = untilMs - _now().millisecondsSinceEpoch;
    return ms > 0 ? Duration(milliseconds: ms) : Duration.zero;
  }

  /// Records [provider] as throttled. Never shortens an already-recorded,
  /// still-active cooldown — so an RPM record arriving while an RPD block is
  /// active (or vice versa) keeps the longer deadline.
  Future<void> recordCooldown({
    required AiProvider provider,
    int? retryDelayMs,
  }) async {
    final now = _now();
    DateTime until;
    final String source;
    if (retryDelayMs != null &&
        retryDelayMs <= AppConstants.guardRpmSuspectThresholdMs) {
      // RPM-ish window: close inside the window, near the reported wait.
      final floor = Duration(milliseconds: AppConstants.guardRpmUntilFloorMs);
      final cap = Duration(milliseconds: AppConstants.guardRpmUntilCapMs);
      until = now.add(
        _clampDuration(Duration(milliseconds: retryDelayMs), floor, cap),
      );
      source = 'rpm-window';
    } else if (retryDelayMs != null) {
      // RPD-ish: block until the real daily reset — never past it — so the
      // next user request is allowed again after the reset.
      final resetIn = _dailyService?.timeUntilPacificReset() ?? Duration.zero;
      final resetAt = now.add(resetIn);
      final byDelay = now.add(Duration(milliseconds: retryDelayMs));
      until = byDelay.isBefore(resetAt) ? byDelay : resetAt;
      if (!until.isAfter(now)) until = byDelay; // no reset info — trust delay
      source = 'rpd-reset';
    } else {
      until = now.add(
        Duration(milliseconds: AppConstants.guardRpmDefaultCooldownMs),
      );
      source = 'rpm-default';
    }

    final newUntilMs = until.millisecondsSinceEpoch;
    final existingMs = _readUntilMs(provider);
    if (existingMs > now.millisecondsSinceEpoch && existingMs >= newUntilMs) {
      return; // never shorten the active guard
    }
    await _writeUntil(provider, newUntilMs, source);
  }

  /// Clears the cooldown for [provider] after a successful generation —
  /// the RPM window has moved on, so the next request can go through.
  void clearOnSuccess(AiProvider provider) => _removeUntil(provider);

  Map<AiProvider, RateLimitGuardEntry> get guardedEntries {
    final store = _readStore();
    final now = _now().millisecondsSinceEpoch;
    final out = <AiProvider, RateLimitGuardEntry>{};
    for (final provider in AiProvider.values) {
      final entry = store[provider.name];
      if (entry is! Map<String, dynamic>) continue;
      final untilMs = entry[_fieldUntilMs];
      if (untilMs is! int || untilMs <= now) continue;
      final source = entry[_fieldSource];
      out[provider] = RateLimitGuardEntry(
        untilMs: untilMs,
        source: source is String ? source : 'unknown',
      );
    }
    return out;
  }

  static Duration _clampDuration(Duration d, Duration min, Duration max) {
    if (d < min) return min;
    if (d > max) return max;
    return d;
  }

  int _readUntilMs(AiProvider provider) {
    final entry = _readStore()[provider.name];
    if (entry is! Map<String, dynamic>) return 0;
    final untilMs = entry[_fieldUntilMs];
    return untilMs is int ? untilMs : 0;
  }

  Map<String, dynamic> _readStore() {
    try {
      final raw = _prefs.getString(_keyStore);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  Future<void> _writeUntil(
    AiProvider provider,
    int untilMs,
    String source,
  ) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final store = _readStore();
    store.removeWhere(
      (_, v) =>
          v is Map<String, dynamic> &&
          (v[_fieldUntilMs] as int?) != null &&
          (v[_fieldUntilMs] as int) <= nowMs,
    );
    store[provider.name] = {_fieldUntilMs: untilMs, _fieldSource: source};
    await _persist(store);
  }

  void _removeUntil(AiProvider provider) {
    final store = _readStore();
    if (!store.containsKey(provider.name)) return;
    store.remove(provider.name);
    _persist(store);
  }

  Future<void> _persist(Map<String, dynamic> store) =>
      _prefs.setString(_keyStore, jsonEncode(store));
}
