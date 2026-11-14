import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/app_theme.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:oreamnos/ui/features/usage/views/usage_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final rawPrefs = await SharedPreferences.getInstance();
    final prefs = PreferencesService(
      prefs: rawPrefs,
      secureStorage: const FlutterSecureStorage(),
    );
    final usage = UsageService(rawPrefs);
    await usage.logUsage(
      UsageLog(
        id: '1',
        timestamp: DateTime.now(),
        providerId: 'gemini',
        modelName: 'gemini-2.5-flash',
        latencyMs: 1200,
        estimatedTokens: 900,
        isSuccess: true,
      ),
    );
    await getIt.reset();
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<PreferencesService>(() => prefs);
    getIt.registerLazySingleton<UsageService>(() => usage);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('charts expose summaries at 200% text without overflow', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1200, 4800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const UsageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp('Token usage')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Success rate')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Average response time')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
