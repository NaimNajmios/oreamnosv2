import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

import '../../domain/models/usage_log.dart';

final usageServiceProvider = ChangeNotifierProvider<UsageService>(
  (ref) => getIt<UsageService>(),
);

@lazySingleton
class UsageService extends ChangeNotifier {
  static const String _keyLogs = 'usage_logs';
  static const int _maxLogs = 50;

  final SharedPreferences _prefs;
  List<UsageLog> _logs = [];

  UsageService(this._prefs) {
    _loadLogs();
  }

  List<UsageLog> get logs => List.unmodifiable(_logs);

  void _loadLogs() {
    final list = _prefs.getStringList(_keyLogs) ?? [];
    _logs = list.map((e) => UsageLog.fromJson(jsonDecode(e))).toList();
    notifyListeners();
  }

  Future<void> logUsage(UsageLog log) async {
    _logs = List.of(_logs)..insert(0, log);
    if (_logs.length > _maxLogs) {
      _logs = _logs.sublist(0, _maxLogs);
    }
    await _saveLogs();
    notifyListeners();
  }

  Future<void> _saveLogs() async {
    final list = _logs.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_keyLogs, list);
  }

  Future<void> clearLogs() async {
    _logs = [];
    await _prefs.remove(_keyLogs);
    notifyListeners();
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
}
