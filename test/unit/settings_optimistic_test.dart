import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/app_theme_mode.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferences double whose writes can fail or throw on demand.
class _FlakyPreferences extends PreferencesService {
  _FlakyPreferences({required super.prefs, required super.secureStorage});

  bool failWrites = false;
  bool throwWrites = false;
  int themeWrites = 0;
  int fanWrites = 0;

  Future<bool> _result(Future<bool> Function() real) async {
    if (throwWrites) throw StateError('secure storage unavailable');
    if (failWrites) return false;
    return real();
  }

  @override
  Future<bool> setThemeMode(AppThemeMode mode) {
    themeWrites++;
    return _result(() => super.setThemeMode(mode));
  }

  @override
  Future<bool> setFanModeEnabled(bool enabled) {
    fanWrites++;
    return _result(() => super.setFanModeEnabled(enabled));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> waitForLoad() async {
    final container = ProviderContainer();
    container.read(settingsViewModelProvider);
    for (var i = 0; i < 100; i++) {
      // ignore: avoid_manual_providers_as_generated_provider_dependency
      if (container.read(settingsViewModelProvider).isInitialized) {
        return container;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Settings state never initialized');
  }

  late _FlakyPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final rawPrefs = await SharedPreferences.getInstance();
    prefs = _FlakyPreferences(
      prefs: rawPrefs,
      secureStorage: const FlutterSecureStorage(),
    );
    await getIt.reset();
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<PreferencesService>(() => prefs);
    getIt.registerLazySingleton<UsageService>(() => UsageService(rawPrefs));
    getIt.registerLazySingleton<LogService>(() => LogService(rawPrefs));
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('SettingsNotifier optimistic writes', () {
    test('a rejected write reverts the theme and reports failure', () async {
      final container = await waitForLoad();
      final notifier = container.read(settingsViewModelProvider.notifier);
      final before = container.read(settingsViewModelProvider).themeMode;
      final next = before == AppThemeMode.dark
          ? AppThemeMode.light
          : AppThemeMode.dark;

      prefs.failWrites = true;
      final saved = await notifier.setThemeMode(next);

      expect(saved, isFalse);
      expect(container.read(settingsViewModelProvider).themeMode, before);
      expect(prefs.themeWrites, 1);

      prefs.failWrites = false;
      expect(await notifier.setThemeMode(next), isTrue);
      expect(container.read(settingsViewModelProvider).themeMode, next);
      expect(prefs.themeMode, next, reason: 'accepted write persists');
      container.dispose();
    });

    test('a throwing write also reverts instead of crashing', () async {
      final container = await waitForLoad();
      final notifier = container.read(settingsViewModelProvider.notifier);
      final before = container.read(settingsViewModelProvider).isFanModeEnabled;

      prefs.throwWrites = true;
      expect(await notifier.setFanModeEnabled(!before), isFalse);
      expect(
        container.read(settingsViewModelProvider).isFanModeEnabled,
        before,
      );
      container.dispose();
    });
  });
}
