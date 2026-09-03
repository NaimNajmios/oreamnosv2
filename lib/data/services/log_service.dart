import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel { debug, info, warning, error }

extension LogLevelX on LogLevel {
  String get label => switch (this) {
    LogLevel.debug => 'DEBUG',
    LogLevel.info => 'INFO',
    LogLevel.warning => 'WARN',
    LogLevel.error => 'ERROR',
  };
}

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? error;
  final String tag;
  final String? details;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.tag = 'App',
    this.details,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = (timestamp.millisecond % 1000).toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get formattedDate {
    final y = timestamp.year.toString();
    final mo = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    return '$y-$mo-$d $formattedTime';
  }

  LogLevel get logLevel {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return LogLevel.debug;
      case 'WARN':
      case 'WARNING':
        return LogLevel.warning;
      case 'ERROR':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level,
    'message': message,
    if (error != null) 'error': error,
    'tag': tag,
    if (details != null) 'details': details,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.parse(json['timestamp'] as String),
    level: json['level'] as String? ?? 'INFO',
    message: json['message'] as String? ?? '',
    error: json['error'] as String?,
    tag: json['tag'] as String? ?? 'App',
    details: json['details'] as String?,
  );
}

/// Abstraction for logging — enables Riverpod injection + mocking.
abstract class ILogService {
  List<LogEntry> get logs;
  void debug(String message, {String tag = 'App', String? details});
  void info(String message, {String tag = 'App', String? details});
  void warning(String message, {String tag = 'App', String? details});
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  void clear();
}

/// Reactive Riverpod provider for debug logs.
final logNotifierProvider = NotifierProvider<LogNotifier, List<LogEntry>>(
  LogNotifier.new,
);

class LogNotifier extends Notifier<List<LogEntry>> {
  late final LogService _service;

  @override
  List<LogEntry> build() {
    _service = getIt<LogService>();
    final unsubscribe = _service.addListener((logs) {
      state = logs;
    });
    ref.onDispose(unsubscribe);
    return _service.logs;
  }

  void debug(String message, {String tag = 'App', String? details}) =>
      _service.debug(message, tag: tag, details: details);
  void info(String message, {String tag = 'App', String? details}) =>
      _service.info(message, tag: tag, details: details);
  void warning(String message, {String tag = 'App', String? details}) =>
      _service.warning(message, tag: tag, details: details);
  void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _service.error(message, error, stackTrace);
  void clear() => _service.clear();
}

@lazySingleton
class LogService implements ILogService {
  LogService(this._prefs) {
    _initPersistence();
  }

  final SharedPreferences _prefs;

  static const String _keyLogs = 'logs_v2';
  final List<LogEntry> _logs = [];
  final int _maxLogs = 200;
  bool _isNotificationPending = false;
  Timer? _persistTimer;
  final List<void Function(List<LogEntry>)> _listeners = [];

  void Function() addListener(void Function(List<LogEntry>) listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  @override
  List<LogEntry> get logs => List.unmodifiable(_logs);

  Future<void> _initPersistence() async {
    try {
      final saved = _prefs.getStringList(_keyLogs);
      if (saved != null && saved.isNotEmpty && _logs.isEmpty) {
        for (final item in saved) {
          try {
            _logs.add(
              LogEntry.fromJson(jsonDecode(item) as Map<String, dynamic>),
            );
          } catch (_) {}
        }
        _scheduleThrottledNotify();
      }
    } catch (_) {}
  }

  void _scheduleSave() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final list = _logs
            .take(100)
            .map((e) => jsonEncode(e.toJson()))
            .toList();
        await _prefs.setStringList(_keyLogs, list);
      } catch (_) {}
    });
  }

  @override
  void debug(String message, {String tag = 'App', String? details}) {
    _addLog(level: 'DEBUG', message: message, tag: tag, details: details);
  }

  @override
  void info(String message, {String tag = 'App', String? details}) {
    _addLog(level: 'INFO', message: message, tag: tag, details: details);
  }

  @override
  void warning(String message, {String tag = 'App', String? details}) {
    _addLog(level: 'WARN', message: message, tag: tag, details: details);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _addLog(
      level: 'ERROR',
      message: message,
      error: '$error\n$stackTrace',
      tag: 'App',
    );
  }

  @override
  void clear() {
    _logs.clear();
    _persistTimer?.cancel();
    _prefs.remove(_keyLogs);
    _scheduleThrottledNotify();
  }

  void _scheduleThrottledNotify() {
    if (_isNotificationPending) return;
    _isNotificationPending = true;
    scheduleMicrotask(() {
      _isNotificationPending = false;
      final currentLogs = logs;
      for (final listener in List.of(_listeners)) {
        listener(currentLogs);
      }
    });
  }

  void _addLog({
    required String level,
    required String message,
    String? error,
    String tag = 'App',
    String? details,
  }) {
    if (_logs.length >= _maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(
      LogEntry(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        error: error,
        tag: tag,
        details: details,
      ),
    );
    if (kDebugMode) {
      print(
        '[$level][$tag] $message ${error != null ? '\nError: $error' : ''}',
      );
    }
    _scheduleThrottledNotify();
    _scheduleSave();
  }
}
