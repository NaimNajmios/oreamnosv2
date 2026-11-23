import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/ui/features/settings/views/debug_log_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    getIt.reset();
    getIt.allowReassignment = true;
  });

  Future<void> pumpScreen(WidgetTester tester, LogService svc) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [logNotifierProvider.overrideWith(LogNotifier.new)],
        child: const MaterialApp(home: DebugLogScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('lists entries with level summary and filters by level', (
    tester,
  ) async {
    final svc = LogService(await SharedPreferences.getInstance());
    getIt.registerLazySingleton(() => svc);
    svc.info('Hello world', tag: 'TestTag');
    svc.error('Boom', tag: 'TestTag');

    await pumpScreen(tester, svc);

    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('Hello world'), findsOneWidget);
    expect(find.textContaining('ERROR 1'), findsOneWidget);
    expect(find.textContaining('INFO 1'), findsOneWidget);

    // Level chip filter → ERROR only.
    await tester.tap(find.widgetWithText(FilterChip, 'ERROR'));
    await tester.pump();
    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('Hello world'), findsNothing);

    // Flush LogService's debounced save so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 520));
  });

  testWidgets('search filters by message', (tester) async {
    final svc = LogService(await SharedPreferences.getInstance());
    getIt.registerLazySingleton(() => svc);
    svc.info('Alpha note', tag: 'TestTag');
    svc.info('Beta note', tag: 'TestTag');

    await pumpScreen(tester, svc);
    // Let LogService's debounced save timer fire so enterText's async-guard
    // sees a quiet loop.
    await tester.pump(const Duration(milliseconds: 520));

    await tester.enterText(find.byType(TextField), 'alp');
    await tester.pump();

    expect(find.text('Alpha note'), findsOneWidget);
    expect(find.text('Beta note'), findsNothing);

    // Flush LogService's debounced save so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 520));
  });
}
