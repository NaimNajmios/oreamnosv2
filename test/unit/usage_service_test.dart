import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oreamnos/config/constants.dart';
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

    test('logUsage caps at UsageService.defaultMaxLogs (500) logs', () async {
      for (int i = 0; i < 505; i++) {
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

      expect(usageService.logs.length, 500);
      expect(usageService.logs.first.id, 'log_504');
      expect(usageService.logs.last.id, 'log_5');
    });

    test(
      'maxLogs is user-adjustable via the usage_log_max_size pref',
      () async {
        await prefs.setInt(AppConstants.keyUsageLogMaxSize, 75);
        final svc = UsageService(prefs);
        expect(svc.maxLogs, 75);

        // reload() re-reads the ring size from prefs.
        await prefs.setInt(AppConstants.keyUsageLogMaxSize, 120);
        await svc.reload();
        expect(svc.maxLogs, 120);
      },
    );

    test('out-of-range usage_log_max_size pref is clamped', () async {
      // Below the minimum clamps to minMaxLogs.
      await prefs.setInt(AppConstants.keyUsageLogMaxSize, 1);
      expect(UsageService(prefs).maxLogs, UsageService.minMaxLogs);
      // Above the maximum clamps to maxMaxLogs.
      await prefs.setInt(AppConstants.keyUsageLogMaxSize, 99999);
      expect(UsageService(prefs).maxLogs, UsageService.maxMaxLogs);
      // Non-positive falls back to the default.
      await prefs.setInt(AppConstants.keyUsageLogMaxSize, 0);
      expect(UsageService(prefs).maxLogs, UsageService.defaultMaxLogs);
    });

    test('_loadLogs skips malformed entries instead of crashing', () async {
      final good = UsageLog(
        id: 'ok',
        timestamp: DateTime.now(),
        providerId: 'gemini',
        isSuccess: true,
        latencyMs: 5,
        estimatedTokens: 1,
      );
      await prefs.setStringList('usage_logs', [
        'not json',
        jsonEncode(good.toJson()),
        '{"id": "broken"}',
      ]);
      final svc = UsageService(prefs);
      expect(svc.logs.single.id, 'ok');
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
      expect(
        usageService.getSuccessRateByProvider('gemini'),
        closeTo(66.67, 0.1),
      );
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
