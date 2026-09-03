import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/domain/models/app_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService', () {
    test('API key roundtrip via secure storage', () async {
      final prefs = await createMockPrefs();
      final svc = createTestPreferencesService(prefs);

      await svc.setApiKey(AiProvider.gemini, 'gem-key-123');
      expect(await svc.getApiKey(AiProvider.gemini), 'gem-key-123');

      await svc.setApiKey(AiProvider.groq, 'groq-key');
      expect(await svc.getApiKey(AiProvider.groq), 'groq-key');
    });

    test('theme + provider + model + tone prefs roundtrip', () async {
      final prefs = await createMockPrefs();
      final svc = createTestPreferencesService(prefs);

      await svc.setThemeMode(AppThemeMode.midnightNoir);
      expect(svc.themeMode, AppThemeMode.midnightNoir);

      await svc.setSelectedProvider(AiProvider.cerebras);
      expect(svc.selectedProvider, AiProvider.cerebras);

      await svc.setSelectedModel(AiProvider.gemini, 'gemini-2.0-flash');
      expect(svc.getSelectedModel(AiProvider.gemini), 'gemini-2.0-flash');

      await svc.setToneMode('santai');
      expect(svc.toneMode, 'santai');
    });

    test('missing keys return defaults, not throws', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = createTestPreferencesService(prefs);

      expect(await svc.getApiKey(AiProvider.gemini), isNull);
      expect(svc.themeMode, AppThemeMode.system);
      expect(svc.selectedProvider, AiProvider.gemini);
      expect(svc.toneMode, 'formal');
    });
  });
}
