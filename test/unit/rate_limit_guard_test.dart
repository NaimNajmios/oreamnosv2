import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/daily_usage_service.dart';
import 'package:oreamnos/data/services/rate_limit_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2026-11-21 20:00 PT (Saturday) — the night before the next Pacific
  // midnight RPD reset.
  final fixedNow = DateTime(2026, 11, 21, 20, 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();
  });

  Future<SharedPreferences> newPrefs() => SharedPreferences.getInstance();

  RateLimitGuard newGuard(
    SharedPreferences prefs,
    DateTime now, {
    DailyUsageClock? dailyNowOverride,
  }) {
    if (dailyNowOverride != null) {
      getIt.registerLazySingleton<DailyUsageService>(
        () => DailyUsageService(prefs, nowOverride: dailyNowOverride),
      );
    }
    return RateLimitGuard(prefs, now: () => now);
  }

  group('RateLimitGuard', () {
    test('nothing recorded → not cooling down', () async {
      final prefs = await newPrefs();
      final guard = newGuard(prefs, fixedNow);
      expect(guard.isCoolingDown(AiProvider.gemini), isFalse);
      expect(guard.isCoolingDown(AiProvider.groq), isFalse);
      expect(guard.timeUntil(AiProvider.gemini), Duration.zero);
      expect(guard.guardedEntries, isEmpty);
    });

    test(
      'RPM delay closes inside the near-minute window, only for that provider',
      () async {
        final prefs = await newPrefs();
        final guard = newGuard(prefs, fixedNow);
        await guard.recordCooldown(
          provider: AiProvider.gemini,
          retryDelayMs: 34000,
        );
        expect(guard.isCoolingDown(AiProvider.gemini), isTrue);
        expect(guard.timeUntil(AiProvider.gemini), const Duration(seconds: 34));
        expect(guard.isCoolingDown(AiProvider.groq), isFalse);
        expect(guard.guardedEntries.keys.toList(), [AiProvider.gemini]);
      },
    );

    test('tiny RPM delay still gets the floor', () async {
      final prefs = await newPrefs();
      final guard = newGuard(prefs, fixedNow);
      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 1000,
      );
      expect(guard.isCoolingDown(AiProvider.gemini), isTrue);
      expect(
        guard.timeUntil(AiProvider.gemini).inSeconds,
        inInclusiveRange(5, 5),
      );
    });

    test('large RPM delay is capped at 90s', () async {
      final prefs = await newPrefs();
      final guard = newGuard(prefs, fixedNow);
      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 600000, // 10 min — over the RPM suspicion threshold
      );
      expect(guard.isCoolingDown(AiProvider.gemini), isTrue);
      expect(
        guard.timeUntil(AiProvider.gemini).inSeconds,
        inInclusiveRange(75, 90),
      );
    });

    test('unparsed delay → default 30s cooldown', () async {
      final prefs = await newPrefs();
      final guard = newGuard(prefs, fixedNow);
      await guard.recordCooldown(provider: AiProvider.groq);
      expect(guard.isCoolingDown(AiProvider.groq), isTrue);
      expect(
        guard.timeUntil(AiProvider.groq).inSeconds,
        inInclusiveRange(25, 31),
      );
    });

    test(
      'RPD-suspect delay closes at the Pacific-midnight reset, never past it',
      () async {
        final prefs = await newPrefs();
        final daily = DailyUsageService(prefs, nowOverride: () => fixedNow);
        final guard = newGuard(
          prefs,
          fixedNow,
          dailyNowOverride: () => fixedNow,
        );

        final reset = daily.timeUntilPacificReset();
        expect(reset, greaterThan(Duration.zero));

        // Delay bigger than the nightly reset → guard must close at the
        // reset, never past it.
        final delayMs = reset.inMilliseconds + 2 * 60 * 60 * 1000;
        await guard.recordCooldown(
          provider: AiProvider.gemini,
          retryDelayMs: delayMs,
        );
        expect(guard.isCoolingDown(AiProvider.gemini), isTrue);
        expect(
          guard.timeUntil(AiProvider.gemini).inMilliseconds,
          closeTo(reset.inMilliseconds, 1),
        );
      },
    );

    test('never shortens an active longer guard', () async {
      final prefs = await newPrefs();
      final guard = newGuard(prefs, fixedNow);
      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 8 * 60 * 60 * 1000, // RPD path — until reset
      );
      final before = guard.timeUntil(AiProvider.gemini);
      expect(before, greaterThan(const Duration(hours: 2)));

      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 60000, // RPM path — shorter than the RPD block
      );
      expect(guard.timeUntil(AiProvider.gemini), before);
    });

    test('extends when the new deadline is longer', () async {
      final prefs = await newPrefs();
      final guard = newGuard(prefs, fixedNow);
      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 30000,
      );
      expect(guard.timeUntil(AiProvider.gemini).inSeconds, greaterThan(20));
      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 60000,
      );
      expect(guard.timeUntil(AiProvider.gemini).inSeconds, greaterThan(50));
    });

    test('clearOnSuccess opens the provider again', () async {
      final prefs = await newPrefs();
      final guard = newGuard(prefs, fixedNow);
      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 60000,
      );
      expect(guard.isCoolingDown(AiProvider.gemini), isTrue);
      guard.clearOnSuccess(AiProvider.gemini);
      expect(guard.isCoolingDown(AiProvider.gemini), isFalse);
      expect(guard.guardedEntries, isEmpty);
    });

    test('expired guard is not cooling down', () async {
      final prefs = await newPrefs();
      var clock = fixedNow;
      final guard = RateLimitGuard(prefs, now: () => clock);
      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 60000,
      );
      expect(guard.isCoolingDown(AiProvider.gemini), isTrue);
      clock = clock.add(const Duration(seconds: 61));
      expect(guard.isCoolingDown(AiProvider.gemini), isFalse);
      expect(guard.timeUntil(AiProvider.gemini), Duration.zero);
    });

    test('persists across guard instances (app restart)', () async {
      final prefs = await newPrefs();
      final guard = newGuard(prefs, fixedNow);
      await guard.recordCooldown(
        provider: AiProvider.gemini,
        retryDelayMs: 60000,
      );
      final restarted = newGuard(prefs, fixedNow);
      expect(restarted.isCoolingDown(AiProvider.gemini), isTrue);
      expect(
        restarted.timeUntil(AiProvider.gemini),
        greaterThan(Duration.zero),
      );
    });
  });
}
