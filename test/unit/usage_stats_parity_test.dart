import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

UsageLog _log(String provider, int latency, bool success) => UsageLog(
  id: const Uuid().v4(),
  timestamp: DateTime.now(),
  providerId: provider,
  modelName: 'm',
  latencyMs: latency,
  estimatedTokens: 10,
  isSuccess: success,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UsageService provider stats (Android parity)', () {
    test('null/empty provider logs return zeros, no crash', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = UsageService(prefs);

      expect(svc.getSuccessRateByProvider('gemini'), 0.0);
      expect(svc.getAllSuccessRates(), isEmpty);
    });

    test('success rates track per-provider attempt mix', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = UsageService(prefs);

      await svc.logUsage(_log('gemini', 100, true));
      await svc.logUsage(_log('gemini', 300, false));
      await svc.logUsage(_log('groq', 50, true));

      expect(svc.getSuccessRateByProvider('gemini'), 50.0);
      expect(svc.getAllSuccessRates()['groq'], 100.0);
      expect(svc.getAllSuccessRates()['cerebras'], isNull);
    });

    test('median/P95 track provider latencies', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = UsageService(prefs);

      await svc.logUsage(_log('gemini', 100, true));
      await svc.logUsage(_log('gemini', 300, true));
      await svc.logUsage(_log('gemini', 200, true));
      await svc.logUsage(_log('groq', 150, true));

      expect(svc.getMedianResponseTimeByProvider('gemini'), closeTo(200, 0.01));
      expect(svc.getMedianResponseTimeByProvider('groq'), 150);
      final p95 = svc.getP95ResponseTimeByProvider('gemini')!;
      expect(p95, greaterThanOrEqualTo(200));
      expect(p95, lessThanOrEqualTo(300));
      expect(svc.getMedianResponseTimeByProvider('cerebras'), isNull);
      expect(svc.getP95ResponseTimeByProvider('cerebras'), isNull);
    });
  });
}
