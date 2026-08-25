import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UsageService', () {
    late SharedPreferences prefs;
    late UsageService usageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      usageService = UsageService(prefs);
    });

    test('initial logs is empty', () {
      expect(usageService.logs, isEmpty);
      expect(usageService.getSuccessRateByProvider('gemini'), 0.0);
      expect(usageService.getAllSuccessRates(), isEmpty);
    });

    test('logUsage adds logs in reverse chronological order', () async {
      final log1 = UsageLog(
        id: '1',
        timestamp: DateTime.now(),
        providerId: 'gemini',
        modelName: 'gemini-1.5-flash',
        isSuccess: true,
        latencyMs: 120,
        estimatedTokens: 150,
      );
      final log2 = UsageLog(
        id: '2',
        timestamp: DateTime.now(),
        providerId: 'groq',
        modelName: 'llama-3.3-70b',
        isSuccess: false,
        latencyMs: 340,
        estimatedTokens: 0,
      );

      await usageService.logUsage(log1);
      await usageService.logUsage(log2);

      expect(usageService.logs.length, 2);
      expect(usageService.logs.first.id, '2');
      expect(usageService.logs.last.id, '1');
    });

    test('logUsage caps at 50 logs', () async {
      for (int i = 0; i < 55; i++) {
        await usageService.logUsage(
          UsageLog(
            id: 'log_$i',
            timestamp: DateTime.now(),
            providerId: 'gemini',
            isSuccess: true,
            latencyMs: 100,
            estimatedTokens: 50,
          ),
        );
      }

      expect(usageService.logs.length, 50);
      expect(usageService.logs.first.id, 'log_54');
      expect(usageService.logs.last.id, 'log_5');
    });

    test('clearLogs removes all logs from memory and storage', () async {
      await usageService.logUsage(
        UsageLog(
          id: '1',
          timestamp: DateTime.now(),
          providerId: 'gemini',
          isSuccess: true,
          latencyMs: 120,
          estimatedTokens: 80,
        ),
      );
      expect(usageService.logs.length, 1);

      await usageService.clearLogs();
      expect(usageService.logs, isEmpty);

      // Verify reloaded service is also empty
      final reloaded = UsageService(prefs);
      expect(reloaded.logs, isEmpty);
    });

    test('getSuccessRateByProvider calculates accurate percentages', () async {
      await usageService.logUsage(
        UsageLog(
          id: '1',
          timestamp: DateTime.now(),
          providerId: 'gemini',
          isSuccess: true,
          latencyMs: 100,
          estimatedTokens: 50,
        ),
      );
      await usageService.logUsage(
        UsageLog(
          id: '2',
          timestamp: DateTime.now(),
          providerId: 'gemini',
          isSuccess: false,
          latencyMs: 200,
          estimatedTokens: 0,
        ),
      );
      await usageService.logUsage(
        UsageLog(
          id: '3',
          timestamp: DateTime.now(),
          providerId: 'gemini',
          isSuccess: true,
          latencyMs: 150,
          estimatedTokens: 60,
        ),
      );
      await usageService.logUsage(
        UsageLog(
          id: '4',
          timestamp: DateTime.now(),
          providerId: 'groq',
          isSuccess: true,
          latencyMs: 80,
          estimatedTokens: 40,
        ),
      );

      // Gemini: 2 success / 3 total = 66.666...%
      expect(usageService.getSuccessRateByProvider('gemini'), closeTo(66.67, 0.1));
      // Groq: 1 success / 1 total = 100%
      expect(usageService.getSuccessRateByProvider('groq'), 100.0);
      // Cerebras: 0 logs = 0%
      expect(usageService.getSuccessRateByProvider('cerebras'), 0.0);

      final allRates = usageService.getAllSuccessRates();
      expect(allRates.containsKey('gemini'), isTrue);
      expect(allRates.containsKey('groq'), isTrue);
      expect(allRates.containsKey('openrouter'), isFalse);
    });
  });
}
