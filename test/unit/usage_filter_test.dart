import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/ui/features/usage/view_models/usage_filter_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences rawPrefs;
  late PreferencesService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    rawPrefs = await SharedPreferences.getInstance();
    prefs = PreferencesService(
      prefs: rawPrefs,
      secureStorage: const FlutterSecureStorage(),
    );
    await getIt.reset();
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<PreferencesService>(() => prefs);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('Usage filter preferences', () {
    test('defaults to all time and every provider', () {
      expect(prefs.usageRangeDays, 0);
      expect(prefs.usageProviderFilter, 'all');
    });

    test('invalid or unset ranges fall back to all time', () async {
      await prefs.setUsageRangeDays(30);
      expect(prefs.usageRangeDays, 30);

      await prefs.setUsageRangeDays(12);
      expect(prefs.usageRangeDays, 0);
      expect(rawPrefs.getInt(AppConstants.keyUsageRangeDays), 0);

      await rawPrefs.setInt(AppConstants.keyUsageRangeDays, 28);
      expect(prefs.usageRangeDays, 0);
    });

    test('provider filter is trimmed and normalised', () async {
      await prefs.setUsageProviderFilter('  GRoQ ');
      expect(prefs.usageProviderFilter, 'groq');

      await prefs.setUsageProviderFilter('   ');
      expect(prefs.usageProviderFilter, 'all');
      expect(rawPrefs.getString(AppConstants.keyUsageProviderFilter), 'all');
    });
  });

  group('UsageFilterNotifier', () {
    test('persists range and provider across a fresh container', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(usageFilterProvider.notifier);

      expect(container.read(usageFilterProvider).rangeDays, 0);
      await notifier.setRangeDays(90);
      await notifier.setProviderFilter('Cerebras');

      expect(container.read(usageFilterProvider).rangeDays, 90);
      expect(container.read(usageFilterProvider).providerFilter, 'cerebras');
      expect(rawPrefs.getInt(AppConstants.keyUsageRangeDays), 90);
      expect(
        rawPrefs.getString(AppConstants.keyUsageProviderFilter),
        'cerebras',
      );

      // A new container reads the persisted values synchronously.
      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      final filter = restored.read(usageFilterProvider);
      expect(filter.rangeDays, 90);
      expect(filter.providerFilter, 'cerebras');
    });

    test('resetToAllTime clears only the range', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(usageFilterProvider.notifier);
      await notifier.setRangeDays(7);
      await notifier.setProviderFilter('gemini');

      await notifier.resetToAllTime();

      expect(container.read(usageFilterProvider).rangeDays, 0);
      expect(container.read(usageFilterProvider).providerFilter, 'gemini');
    });
  });
}
