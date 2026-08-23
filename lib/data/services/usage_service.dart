import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/usage_log.dart';

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
}

