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
      expect(svc.getAverageResponseTimeByProvider('gemini'), 0.0);
      expect(svc.getFastestResponseTimeByProvider('gemini'), isNull);
      expect(svc.getSlowestResponseTimeByProvider('gemini'), isNull);
      expect(svc.getAllSuccessRates(), isEmpty);
    });

    test('average/fastest/slowest per provider', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = UsageService(prefs);

      await svc.logUsage(_log('gemini', 100, true));
      await svc.logUsage(_log('gemini', 300, false));
      await svc.logUsage(_log('groq', 50, true));

      expect(svc.getSuccessRateByProvider('gemini'), 50.0);
      expect(svc.getAverageResponseTimeByProvider('gemini'), 200.0);
      expect(svc.getFastestResponseTimeByProvider('gemini'), 100);
      expect(svc.getSlowestResponseTimeByProvider('gemini'), 300);
      expect(svc.getAverageResponseTimeByProvider('groq'), 50.0);
      expect(svc.getAllSuccessRates()['groq'], 100.0);
    });
  });
}
