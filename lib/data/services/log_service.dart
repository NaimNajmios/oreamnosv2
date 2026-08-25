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

/// Abstraction for logging — enables Riverpod injection + mocking.
/// Phase 0: introduced alongside the existing singleton to allow incremental
/// migration. Phase A will replace `LogService()` direct calls with
/// `ref.watch(logServiceProvider)`.
abstract class ILogService implements Listenable {
  List<LogEntry> get logs;
  void info(String message);
  void warning(String message);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  void clear();
}

/// A simple in-memory ring buffer for debugging logs.
class LogService extends ChangeNotifier implements ILogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  /// Test-only constructor — creates a non-singleton instance for injection.
  @visibleForTesting
  LogService.test();

  final List<LogEntry> _logs = [];
  final int _maxLogs = 200;

  @override
  List<LogEntry> get logs => List.unmodifiable(_logs);

  @override
  void info(String message) {
    _addLog(level: 'INFO', message: message);
  }

  @override
  void warning(String message) {
    _addLog(level: 'WARN', message: message);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _addLog(level: 'ERROR', message: message, error: '$error\n$stackTrace');
  }

  @override
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

