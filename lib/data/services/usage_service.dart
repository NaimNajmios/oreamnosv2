import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

import '../../domain/models/usage_log.dart';

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
  double getSuccessRateByProvider(String providerId) =>
      _service.getSuccessRateByProvider(providerId);
  Map<String, double> getAllSuccessRates() => _service.getAllSuccessRates();
}

@lazySingleton
class UsageService {
  static const String _keyLogs = 'usage_logs';
  static const int _maxLogs = 50;

  final SharedPreferences _prefs;
  List<UsageLog> _logs = [];
  final List<void Function(List<UsageLog>)> _listeners = [];

  UsageService(this._prefs) {
    _loadLogs();
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
    final list = _prefs.getStringList(_keyLogs) ?? [];
    _logs = list.map((e) => UsageLog.fromJson(jsonDecode(e))).toList();
    _notify();
  }

  Future<void> reload() async {
    try {
      await _prefs.reload();
    } catch (_) {}
    _loadLogs();
  }

  Future<void> logUsage(UsageLog log) async {
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

  /// Average response latency in ms for a provider (Android
  /// `getAverageResponseTimeByProvider` parity). Returns 0 when no logs.
  double getAverageResponseTimeByProvider(String providerId) {
    final providerLogs = _logs
        .where((l) => l.providerId.toLowerCase() == providerId.toLowerCase())
        .toList();
    if (providerLogs.isEmpty) return 0.0;
    final total = providerLogs.fold<int>(0, (sum, l) => sum + l.latencyMs);
    return total / providerLogs.length;
  }

  /// Fastest recorded latency in ms for a provider, or null when no logs.
  int? getFastestResponseTimeByProvider(String providerId) {
    final providerLogs = _logs
        .where((l) => l.providerId.toLowerCase() == providerId.toLowerCase())
        .toList();
    if (providerLogs.isEmpty) return null;
    return providerLogs.map((l) => l.latencyMs).reduce((a, b) => a < b ? a : b);
  }

  /// Slowest recorded latency in ms for a provider, or null when no logs.
  int? getSlowestResponseTimeByProvider(String providerId) {
    final providerLogs = _logs
        .where((l) => l.providerId.toLowerCase() == providerId.toLowerCase())
        .toList();
    if (providerLogs.isEmpty) return null;
    return providerLogs.map((l) => l.latencyMs).reduce((a, b) => a > b ? a : b);
  }
}
