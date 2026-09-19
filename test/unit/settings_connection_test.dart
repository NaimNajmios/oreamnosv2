import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies the Settings 3-step setup persistence:
/// key + model + connection test must survive an app restart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitForLoad(ProviderContainer container) async {
    // SettingsNotifier._loadState runs async from build(); poll until done.
    for (var i = 0; i < 100; i++) {
      // ignore: avoid_manual_providers_as_generated_provider_dependency
      if (container.read(settingsViewModelProvider).isInitialized) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Settings state never initialized');
  }

  Future<(ProviderContainer, PreferencesService)> setUpContainer() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    final prefService = PreferencesService(
      prefs: prefs,
      secureStorage: storage,
    );

    await getIt.reset();
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<PreferencesService>(() => prefService);
    getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
    getIt.registerLazySingleton<LogService>(() => LogService(prefs));

    final container = ProviderContainer();
    // Trigger build then wait for the async _loadState to finish.
    container.read(settingsViewModelProvider);
    await waitForLoad(container);
    return (container, prefService);
  }

  group('Connection test persistence', () {
    test(
      'successful test survives restart (new notifier, same prefs)',
      () async {
        final (container, prefService) = await setUpContainer();

        final notifier = container.read(settingsViewModelProvider.notifier);
        await prefService.setApiKey(AiProvider.gemini, 'key-1');
        await notifier.setApiKey(AiProvider.gemini, 'key-1');
        await notifier.setSelectedModel('gemini-2.0-flash');
        await notifier.setLastTestResult(true);
        expect(container.read(settingsViewModelProvider).lastTestOk, isTrue);

        // Simulate app restart: fresh container over the same prefs.
        container.dispose();
        final container2 = ProviderContainer();
        container2.read(settingsViewModelProvider);
        await waitForLoad(container2);

        final restored = container2.read(settingsViewModelProvider);
        expect(restored.lastTestOk, isTrue);
        expect(restored.lastTestedAt, isNotNull);
        container2.dispose();
      },
    );

    test('failed test also persists', () async {
      final (container, _) = await setUpContainer();

      final notifier = container.read(settingsViewModelProvider.notifier);
      await notifier.setLastTestResult(false);

      container.dispose();
      final container2 = ProviderContainer();
      container2.read(settingsViewModelProvider);
      await waitForLoad(container2);

      expect(container2.read(settingsViewModelProvider).lastTestOk, isFalse);
      container2.dispose();
    });

    test('results are isolated per provider', () async {
      final (container, _) = await setUpContainer();

      final notifier = container.read(settingsViewModelProvider.notifier);
      await notifier.setLastTestResult(true);
      await notifier.setSelectedProvider(AiProvider.groq);
      // Groq was never tested → unverified.
      expect(container.read(settingsViewModelProvider).lastTestOk, isNull);
      // Switching back restores Gemini's persisted pass.
      await notifier.setSelectedProvider(AiProvider.gemini);
      expect(container.read(settingsViewModelProvider).lastTestOk, isTrue);
      container.dispose();
    });

    test('changing API key invalidates the verified flag', () async {
      final (container, prefService) = await setUpContainer();

      final notifier = container.read(settingsViewModelProvider.notifier);
      await notifier.setLastTestResult(true);
      expect(prefService.getLastTestOk(AiProvider.gemini), isTrue);

      await notifier.setApiKey(AiProvider.gemini, 'rotated-key');
      expect(container.read(settingsViewModelProvider).lastTestOk, isNull);
      expect(prefService.getLastTestOk(AiProvider.gemini), isNull);
      container.dispose();
    });

    test('changing model invalidates the verified flag', () async {
      final (container, prefService) = await setUpContainer();

      final notifier = container.read(settingsViewModelProvider.notifier);
      await notifier.setLastTestResult(true);

      await notifier.setSelectedModel('gemini-2.5-flash');
      expect(container.read(settingsViewModelProvider).lastTestOk, isNull);
      expect(prefService.getLastTestOk(AiProvider.gemini), isNull);
      container.dispose();
    });
  });
}
