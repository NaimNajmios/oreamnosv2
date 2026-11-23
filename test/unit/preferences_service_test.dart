import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/constants.dart';
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
      expect(svc.persistGenerationOptions, isFalse);
    });

    test('connection test result roundtrip per provider', () async {
      final prefs = await createMockPrefs();
      final svc = createTestPreferencesService(prefs);

      expect(svc.getLastTestOk(AiProvider.gemini), isNull);
      expect(svc.getLastTestedAt(AiProvider.gemini), isNull);

      final at = DateTime(2026, 9, 19, 12, 30);
      await svc.setLastTestResult(AiProvider.gemini, true, at);
      expect(svc.getLastTestOk(AiProvider.gemini), isTrue);
      expect(svc.getLastTestedAt(AiProvider.gemini), at);

      // Other providers are unaffected.
      expect(svc.getLastTestOk(AiProvider.groq), isNull);

      await svc.clearLastTestResult(AiProvider.gemini);
      expect(svc.getLastTestOk(AiProvider.gemini), isNull);
      expect(svc.getLastTestedAt(AiProvider.gemini), isNull);
    });

    test('generation options persistence roundtrip', () async {
      final prefs = await createMockPrefs();
      final svc = createTestPreferencesService(prefs);

      expect(svc.persistGenerationOptions, isFalse);
      expect(svc.lastPromptLength, 'medium');
      expect(svc.lastIsResearchMode, isFalse);
      expect(svc.lastKeepStructure, isFalse);

      await svc.setPersistGenerationOptions(true);
      await svc.setLastPromptLength('long');
      await svc.setLastIsResearchMode(true);
      await svc.setLastKeepStructure(true);

      expect(svc.persistGenerationOptions, isTrue);
      expect(svc.lastPromptLength, 'long');
      expect(svc.lastIsResearchMode, isTrue);
      expect(svc.lastKeepStructure, isTrue);
    });

    test('exportSettings/importSettings round-trip typed settings', () async {
      final prefs = await createMockPrefs();
      final svc = createTestPreferencesService(prefs);

      await svc.setThemeMode(AppThemeMode.midnightNoir);
      await svc.setToneMode('casual');
      await svc.setReadingTextSize(19.5);
      await svc.setFanModeEnabled(true);
      await svc.setFanClubName('Arsenal');
      await svc.setShowWidgetSnippet(true);

      final snapshot = await svc.exportSettings();
      expect(
        snapshot[AppConstants.keyThemeMode],
        AppThemeMode.midnightNoir.name,
      );
      expect(snapshot[AppConstants.keyReadingTextSize], 19.5);

      final prefs2 = await createMockPrefs();
      final svc2 = createTestPreferencesService(prefs2);
      await svc2.importSettings(snapshot);
      expect(svc2.themeMode, AppThemeMode.midnightNoir);
      expect(svc2.toneMode, 'casual');
      expect(svc2.readingTextSize, 19.5);
      expect(svc2.isFanModeEnabled, isTrue);
      expect(svc2.fanClubName, 'Arsenal');
      expect(svc2.showWidgetSnippet, isTrue);
    });
  });
}
