import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/ui/features/generate/views/generate_screen.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quick AI-provider switch on the Generate screen:
/// tapping the provider row opens the provider-only picker (not Settings),
/// and the row shows provider + effective model.
///
/// NOTE: uses bounded `pump()` calls instead of `pumpAndSettle()` because the
/// Generate screen owns repeating animations that never settle in tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> setUp() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    final prefService = PreferencesService(
      prefs: prefs,
      secureStorage: storage,
    );
    await prefService.setSelectedModel(AiProvider.gemini, 'gemini-2.0-flash');

    await getIt.reset();
    await configureDependencies();
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<PreferencesService>(() => prefService);
    getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
    getIt.registerLazySingleton<LogService>(() => LogService(prefs));

    final container = ProviderContainer();
    container.read(settingsViewModelProvider);
    return container;
  }

  Future<void> pumpGenerate(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GenerateScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('Generate quick provider switch', () {
    testWidgets('row shows provider + model; tap opens provider picker', (
      tester,
    ) async {
      final container = await setUp();
      addTearDown(container.dispose);
      await pumpGenerate(tester, container);

      expect(tester.takeException(), isNull);
      // Provider + effective model label, alongside the tone.
      expect(find.text('Gemini • gemini-2.0-flash • Formal'), findsOneWidget);

      await tester.tap(find.text('Gemini • gemini-2.0-flash • Formal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Select AI Provider'), findsOneWidget);
      // Full Settings is NOT pushed for the quick switch.
      expect(find.text('Active Provider'), findsNothing);
    });

    testWidgets('selecting Groq updates row and settings state', (
      tester,
    ) async {
      final container = await setUp();
      addTearDown(container.dispose);
      await pumpGenerate(tester, container);

      await tester.tap(find.text('Gemini • gemini-2.0-flash • Formal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Groq'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Select AI Provider'), findsNothing);
      expect(
        container.read(settingsViewModelProvider).selectedProvider,
        AiProvider.groq,
      );
      // Groq has no explicit model → provider default shown.
      expect(
        find.text('Groq • ${AiProvider.groq.defaultModelId} • Formal'),
        findsOneWidget,
      );
    });

    testWidgets('tune icon offers Model & Settings without leaving', (
      tester,
    ) async {
      final container = await setUp();
      addTearDown(container.dispose);
      await pumpGenerate(tester, container);

      final tune = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Model & Settings',
      );
      expect(tune, findsOneWidget);
      expect(tester.widget<IconButton>(tune).onPressed, isNotNull);
    });
  });
}
