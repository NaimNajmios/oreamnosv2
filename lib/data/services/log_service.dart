import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? error;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
  });
}

/// A simple in-memory ring buffer for debugging logs.
class LogService extends ChangeNotifier {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<LogEntry> _logs = [];
  final int _maxLogs = 200;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void info(String message) {
    _addLog(level: 'INFO', message: message);
  }

  void warning(String message) {
    _addLog(level: 'WARN', message: message);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _addLog(level: 'ERROR', message: message, error: '$error\n$stackTrace');
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  void _addLog({required String level, required String message, String? error}) {
    if (_logs.length >= _maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
    ));
    if (kDebugMode) {
      print('[$level] $message ${error != null ? '\nError: $error' : ''}');
    }
    notifyListeners();
  }
}

