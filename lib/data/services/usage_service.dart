import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

import '../../config/constants.dart';
import '../../domain/models/usage_log.dart';
import 'daily_usage_service.dart';

final usageNotifierProvider = NotifierProvider<UsageNotifier, List<UsageLog>>(
  UsageNotifier.new,
);

class UsageNotifier extends Notifier<List<UsageLog>> {
  late final UsageService _service;

  @override
  List<UsageLog> build() {
    _service = getIt<UsageService>();
    final unsubscribe = _service.addListener((logs) {
      state = logs;
    });
    ref.onDispose(unsubscribe);
    return _service.logs;
  }

  Future<void> logUsage(UsageLog log) => _service.logUsage(log);
  Future<void> clearLogs() => _service.clearLogs();
  Future<void> reload() => _service.reload();
  int get maxLogs => _service.maxLogs;
}

@lazySingleton
class UsageService {
  static const String _keyLogs = 'usage_logs';

  /// Historical default ring size.
  static const int defaultMaxLogs = AppConstants.usageLogDefaultMaxSize;

  /// Adjusted value range for the user-adjustable history cap.
  static const int minMaxLogs = AppConstants.usageLogMinSize;
  static const int maxMaxLogs = AppConstants.usageLogMaxSize;

  final SharedPreferences _prefs;
  final DailyUsageService? _dailyUsage;
  int _maxLogs;
  List<UsageLog> _logs = [];
  final List<void Function(List<UsageLog>)> _listeners = [];

  UsageService(this._prefs, [this._dailyUsage, int? maxLogs])
    : _maxLogs = _resolveMaxLogs(_prefs, maxLogs) {
    _loadLogs();
  }

  /// Current ring-buffer cap. Read live so pref changes surface via reload().
  int get maxLogs => _maxLogs;

  static int _resolveMaxLogs(SharedPreferences prefs, int? override) {
    final v = override ?? prefs.getInt(AppConstants.keyUsageLogMaxSize);
    if (v == null || v <= 0) return defaultMaxLogs;
    return v.clamp(minMaxLogs, maxMaxLogs);
  }

  void Function() addListener(void Function(List<UsageLog>) listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _notify() {
    final currentLogs = logs;
    for (final listener in List.of(_listeners)) {
      listener(currentLogs);
    }
  }

  List<UsageLog> get logs => List.unmodifiable(_logs);

  void _loadLogs() {
    final list = _prefs.getStringList(_keyLogs) ?? const [];
    final loaded = <UsageLog>[];
    for (final entry in list) {
      try {
        loaded.add(UsageLog.fromJson(jsonDecode(entry)));
      } catch (_) {
        // Skip malformed entries instead of crashing the whole ring.
      }
    }
    _logs = loaded.length > _maxLogs
        ? loaded.sublist(loaded.length - _maxLogs)
        : loaded;
    _notify();
  }

  Future<void> reload() async {
    try {
      await _prefs.reload();
    } catch (_) {}
    _maxLogs = _resolveMaxLogs(_prefs, null);
    _loadLogs();
  }

  Future<void> logUsage(UsageLog log) async {
    // Daily RPD budget visibility — every attempt (success or failure)
    // counts against the provider window, including 429-burned ones.
    try {
      await _dailyUsage?.recordRequest(log.providerId, log.modelName);
    } catch (_) {}
    _logs = List.of(_logs)..insert(0, log);
    if (_logs.length > _maxLogs) {
      _logs = _logs.sublist(0, _maxLogs);
    }
    await _saveLogs();
    _notify();
  }

  Future<void> _saveLogs() async {
    final list = _logs.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_keyLogs, list);
  }

  Future<void> clearLogs() async {
    _logs = [];
    await _prefs.remove(_keyLogs);
    _notify();
  }

  double getSuccessRateByProvider(String providerId) {
    final providerLogs = _logs
        .where((l) => l.providerId.toLowerCase() == providerId.toLowerCase())
        .toList();
    if (providerLogs.isEmpty) return 0.0;
    final successes = providerLogs.where((l) => l.isSuccess).length;
    return (successes / providerLogs.length) * 100.0;
  }

  Map<String, double> getAllSuccessRates() {
    final map = <String, double>{};
    for (final p in ['gemini', 'groq', 'openrouter', 'cerebras']) {
      if (_logs.any((l) => l.providerId.toLowerCase() == p)) {
        map[p] = getSuccessRateByProvider(p);
      }
    }
    return map;
  }

  /// Median latency of a provider's logs, or null when the provider has no
  /// logs. Uses the sorted middle when the count is odd, and the later of
  /// the two middle values when even (matches common "percentile"
  /// conventions for display).
  double? getMedianResponseTimeByProvider(String providerId) {
    final latencies =
        _logs
            .where(
              (l) => l.providerId.toLowerCase() == providerId.toLowerCase(),
            )
            .map((l) => l.latencyMs)
            .toList()
          ..sort();
    if (latencies.isEmpty) return null;
    final mid = latencies.length ~/ 2;
    return latencies.length.isOdd
        ? latencies[mid].toDouble()
        : (latencies[mid - 1] + latencies[mid]) / 2;
  }

  /// Approximate 95th-percentile latency of a provider's logs (linear
  /// interpolation), or null when the provider has no logs.
  int? getP95ResponseTimeByProvider(String providerId) {
    final latencies =
        _logs
            .where(
              (l) => l.providerId.toLowerCase() == providerId.toLowerCase(),
            )
            .map((l) => l.latencyMs)
            .toList()
          ..sort();
    if (latencies.isEmpty) return null;
    if (latencies.length == 1) return latencies.first;
    final rank = 0.95 * (latencies.length - 1);
    final lower = rank.floor();
    final upper = rank.ceil();
    if (lower == upper) return latencies[lower];
    final weight = rank - lower;
    return (latencies[lower] * (1 - weight) + latencies[upper] * weight)
        .round();
  }
}
