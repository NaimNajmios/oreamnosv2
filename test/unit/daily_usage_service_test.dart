import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/data/services/daily_usage_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyUsageService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    DailyUsageService service({DateTime Function()? nowOverride}) =>
        DailyUsageService(prefs, nowOverride: nowOverride);

    group('recordRequest counting', () {
      test('counts per provider+model pair, failures included', () async {
        final svc = service();
        await svc.recordRequest('gemini', 'gemini-2.0-flash');
        await svc.recordRequest('gemini', 'gemini-2.0-flash');
        await svc.recordRequest('gemini', 'gemini-2.0-flash');

        final quotas = svc.todayGeminiQuota();
        expect(quotas, hasLength(1));
        expect(quotas.single.modelId, 'gemini-2.0-flash');
        expect(quotas.single.requestsToday, 3);
      });

      test('separates counts by model', () async {
        final svc = service();
        await svc.recordRequest('gemini', 'gemini-2.0-flash');
        await svc.recordRequest('gemini', 'gemini-2.5-flash');

        final quotas = svc.todayGeminiQuota();
        expect(quotas, hasLength(2));
        expect(quotas.every((q) => q.requestsToday == 1), isTrue);
      });

      test('ignores non-gemini providers in the gemini view', () async {
        final svc = service();
        await svc.recordRequest('groq', 'llama-3.3-70b-versatile');

        expect(svc.todayGeminiQuota(), isEmpty);
        expect(svc.hasGeminiActivityToday(), isFalse);
      });

      test('ignores vision pseudo-provider entirely', () async {
        final svc = service();
        await svc.recordRequest('vision', 'vision-chain');

        expect(svc.todayGeminiQuota(), isEmpty);
        expect(svc.hasGeminiActivityToday(), isFalse);
      });

      test('null model name is grouped under unknown', () async {
        final svc = service();
        await svc.recordRequest('gemini', null);

        final quotas = svc.todayGeminiQuota();
        expect(quotas.single.modelId, 'unknown');
        expect(quotas.single.budget, AppConstants.defaultDailyQuota);
      });
    });

    group('budgetForModel', () {
      test('maps known 2.0 / 2.5 free-tier budgets', () {
        expect(DailyUsageService.budgetForModel('gemini-2.0-flash'), 1500);
        expect(
          DailyUsageService.budgetForModel('models/gemini-2.0-flash'),
          1500,
        );
        expect(DailyUsageService.budgetForModel('gemini-2.0-flash-lite'), 1500);
        expect(DailyUsageService.budgetForModel('gemini-2.5-flash'), 500);
        expect(DailyUsageService.budgetForModel('gemini-2.5-flash-lite'), 1000);
      });

      test('falls back to the conservative default for unknown models', () {
        expect(
          DailyUsageService.budgetForModel('some-future-model'),
          AppConstants.defaultDailyQuota,
        );
        expect(
          DailyUsageService.budgetForModel(null),
          AppConstants.defaultDailyQuota,
        );
      });
    });

    group('Pacific day key', () {
      test('handles standard-time (PST) boundary: 08:00 UTC rollover', () {
        // Jan 15, 2026: PST (UTC-8). 07:59:59 UTC = Jan 14 23:59:59 PT.
        expect(
          DailyUsageService.pacificDayKeyNowUtc(
            DateTime.utc(2026, 1, 15, 7, 59, 59),
          ),
          '2026-01-14',
        );
        expect(
          DailyUsageService.pacificDayKeyNowUtc(
            DateTime.utc(2026, 1, 15, 8, 0, 0),
          ),
          '2026-01-15',
        );
      });

      test('handles daylight-time (PDT) boundary: 07:00 UTC rollover', () {
        // Jul 15, 2026: PDT (UTC-7).
        expect(
          DailyUsageService.pacificDayKeyNowUtc(
            DateTime.utc(2026, 7, 15, 6, 59, 59),
          ),
          '2026-07-14',
        );
        expect(
          DailyUsageService.pacificDayKeyNowUtc(
            DateTime.utc(2026, 7, 15, 7, 0, 0),
          ),
          '2026-07-15',
        );
      });

      test('day boundary straddles DST transition days correctly', () {
        // Mar 8, 2026 = second Sunday (US DST start mid-morning Mar 8):
        // early morning is still PST (07:00 UTC not yet the boundary).
        expect(
          DailyUsageService.pacificDayKeyNowUtc(
            DateTime.utc(2026, 3, 8, 6, 59, 59),
          ),
          '2026-03-07',
        );
        // Nov 1, 2026 = first Sunday (DST ends): evening still the same day.
        expect(
          DailyUsageService.pacificDayKeyNowUtc(
            DateTime.utc(2026, 11, 1, 9, 0, 0),
          ),
          '2026-11-01',
        );
      });
    });

    group('rollover and pruning', () {
      test('counters reset when the Pacific day changes', () async {
        var current = DateTime.utc(2026, 1, 14, 20, 0, 0); // Jan 14 PT
        final svc = service(nowOverride: () => current);
        await svc.recordRequest('gemini', 'gemini-2.0-flash');
        await svc.recordRequest('gemini', 'gemini-2.0-flash');
        expect(svc.todayGeminiQuota().single.requestsToday, 2);

        // Advance to Jan 15 PT (UTC 21:30 = 13:30 PST next day).
        current = DateTime.utc(2026, 1, 15, 21, 30, 0);
        expect(svc.todayGeminiQuota(), isEmpty);
        expect(svc.hasGeminiActivityToday(), isFalse);
      });

      test('prunes days older than yesterday on next write', () async {
        var current = DateTime.utc(2026, 1, 14, 20, 0, 0);
        final svc = service(nowOverride: () => current);
        await svc.recordRequest('gemini', 'gemini-2.0-flash');

        current = DateTime.utc(2026, 1, 20, 20, 0, 0); // 6 days later
        await svc.recordRequest('groq', 'llama-3.3-70b');

        final raw = prefs.getString('daily_usage_v1');
        expect(raw, isNotNull);
        final store = raw!;
        // Stale Jan-14 bucket must be gone after the keep-today+yesterday
        // prune on write.
        expect(store.contains('2026-01-14'), isFalse);
      });
    });

    group('threshold classification', () {
      test('amber at 80%, red at 100%', () {
        // dailyQuotaWarnThreshold is 0.8 → warn from 8/10, exhausted at 10/10.
        const under = DailyQuota(
          modelId: 'under',
          requestsToday: 7,
          budget: 10,
        );
        expect(under.isWarning, isFalse);
        expect(under.isExhausted, isFalse);

        final amber = DailyQuota(
          modelId: 'amber',
          requestsToday: 8,
          budget: 10,
        );
        expect(amber.isWarning, isTrue);
        expect(amber.isExhausted, isFalse);

        final red = DailyQuota(modelId: 'red', requestsToday: 10, budget: 10);
        expect(red.isWarning, isTrue);
        expect(red.isExhausted, isTrue);
        expect(red.fraction, 1.0);
      });

      test('fraction clamps over-budget counts', () {
        const over = DailyQuota(modelId: 'over', requestsToday: 15, budget: 10);
        expect(over.fraction, 1.0);
        expect(over.isWarning, isTrue);
      });

      test('live-recorded counts map to real model budgets', () async {
        final svc = service();
        await svc.recordRequest('gemini', 'gemini-2.5-flash');
        final q = svc.todayGeminiQuota().single;
        expect(q.budget, 500);
        expect(q.requestsToday, 1);
        expect(q.isWarning, isFalse);
      });
    });

    group('timeUntilPacificReset', () {
      test('returns 23.5h at 08:30 UTC during PST', () {
        final svc = service(
          nowOverride: () => DateTime.utc(2026, 1, 15, 8, 30, 0),
        );
        final reset = svc.timeUntilPacificReset();
        expect(reset.inHours, 23);
        // ~30 min remainder (1-min resolution)
        expect(reset.inMinutes % 60, inInclusiveRange(29, 31));
      });

      test('returns ~23h at 07:30 UTC during PDT', () {
        final svc = service(
          nowOverride: () => DateTime.utc(2026, 7, 15, 7, 30, 0),
        );
        final reset = svc.timeUntilPacificReset();
        expect(reset.inHours, 23);
        expect(reset.inMinutes % 60, inInclusiveRange(29, 31));
      });
    });

    group('UsageService forwarding', () {
      test('logUsage increments the daily counter for all attempts', () async {
        final daily = service();
        final usage = UsageService(prefs, daily);

        await usage.logUsage(
          UsageLog(
            id: '1',
            timestamp: DateTime.now(),
            providerId: 'gemini',
            modelName: 'gemini-2.0-flash',
            latencyMs: 100,
            estimatedTokens: 0,
            isSuccess: true,
          ),
        );
        await usage.logUsage(
          UsageLog(
            id: '2',
            timestamp: DateTime.now(),
            providerId: 'gemini',
            modelName: 'gemini-2.0-flash',
            latencyMs: 100,
            estimatedTokens: 0,
            isSuccess: false,
          ),
        );

        // Both success and failure count.
        final q = daily.todayGeminiQuota();
        expect(q.single.requestsToday, 2);
      });

      test('clearLogs does not reset the daily counter', () async {
        final daily = service();
        final usage = UsageService(prefs, daily);
        await usage.logUsage(
          UsageLog(
            id: '1',
            timestamp: DateTime.now(),
            providerId: 'gemini',
            modelName: 'gemini-2.0-flash',
            latencyMs: 100,
            estimatedTokens: 0,
            isSuccess: true,
          ),
        );
        await usage.clearLogs();

        expect(daily.todayGeminiQuota().single.requestsToday, 1);
      });
    });
  });
}
