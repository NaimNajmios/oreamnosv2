import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> waitForLoad() async {
    final container = ProviderContainer();
    container.read(settingsViewModelProvider);
    for (var i = 0; i < 100; i++) {
      if (container.read(settingsViewModelProvider).isInitialized) {
        return container;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Settings state never initialized');
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await getIt.reset();
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<PreferencesService>(
      () => PreferencesService(
        prefs: prefs,
        secureStorage: const FlutterSecureStorage(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('setReadingTextSize clamps to the 12–24 range', () async {
    final container = await waitForLoad();
    final notifier = container.read(settingsViewModelProvider.notifier);

    await notifier.setReadingTextSize(9);
    expect(container.read(settingsViewModelProvider).readingTextSize, 12.0);

    await notifier.setReadingTextSize(99);
    expect(container.read(settingsViewModelProvider).readingTextSize, 24.0);

    await notifier.setReadingTextSize(18);
    expect(container.read(settingsViewModelProvider).readingTextSize, 18.0);
  });
}
