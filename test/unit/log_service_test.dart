import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oreamnos/data/services/log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogService', () {
    late LogService logService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      logService = LogService(await SharedPreferences.getInstance());
      logService.clear();
    });

    test('initial logs is empty after clear', () {
      expect(logService.logs, isEmpty);
    });

    test('logs debug, info, warning, and error messages', () async {
      logService.debug('Debug message', tag: 'TestTag', details: 'details');
      logService.info('Info message', tag: 'Network');
      logService.warning('Warning message');
      logService.error('Error message', Exception('Test Exception'));

      // Microtask for throttled notification
      await Future.delayed(const Duration(milliseconds: 10));

      expect(logService.logs.length, 4);
      expect(logService.logs[0].level, 'DEBUG');
      expect(logService.logs[0].tag, 'TestTag');
      expect(logService.logs[0].details, 'details');

      expect(logService.logs[1].level, 'INFO');
      expect(logService.logs[1].tag, 'Network');

      expect(logService.logs[2].level, 'WARN');

      expect(logService.logs[3].level, 'ERROR');
      expect(logService.logs[3].error, contains('Test Exception'));
    });

    test('log entry formatting functions work properly', () {
      final entry = LogEntry(
        timestamp: DateTime(2026, 8, 25, 14, 30, 45, 123),
        level: 'DEBUG',
        message: 'Test message',
      );

      expect(entry.formattedTime, '14:30:45.123');
      expect(entry.formattedDate, '2026-08-25 14:30:45.123');
      expect(entry.logLevel, LogLevel.debug);

      final json = entry.toJson();
      final restored = LogEntry.fromJson(json);
      expect(restored.message, entry.message);
      expect(restored.level, entry.level);
    });

    test('clear removes logs immediately', () async {
      logService.info('Message');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(logService.logs.length, 1);

      logService.clear();
      expect(logService.logs, isEmpty);
    });
  });
}
