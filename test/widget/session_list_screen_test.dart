import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:oreamnos/ui/features/usage/views/session_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();
    getIt.allowReassignment = true;
  });

  testWidgets('shows success and failure rows; failure shows error text', (
    tester,
  ) async {
    final svc = UsageService(await SharedPreferences.getInstance());
    getIt.registerLazySingleton<UsageService>(() => svc);
    await svc.logUsage(
      UsageLog(
        id: '1',
        timestamp: DateTime.now(),
        providerId: 'gemini',
        modelName: 'gemini-2.5-flash',
        latencyMs: 100,
        estimatedTokens: 40,
        isSuccess: true,
      ),
    );
    await svc.logUsage(
      UsageLog(
        id: '2',
        timestamp: DateTime.now(),
        providerId: 'groq',
        modelName: 'llama-3.3-70b',
        latencyMs: 5,
        estimatedTokens: 0,
        isSuccess: false,
        error: 'Rate limited — retry in 30s',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [usageNotifierProvider.overrideWith(UsageNotifier.new)],
        child: const MaterialApp(home: SessionListScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('gemini • gemini-2.5-flash'), findsOneWidget);
    expect(find.text('40 tokens'), findsOneWidget);
    expect(find.text('Rate limited — retry in 30s'), findsOneWidget);
  });

  testWidgets('filters provider rows via chips; empty state after clear', (
    tester,
  ) async {
    final svc = UsageService(await SharedPreferences.getInstance());
    getIt.registerLazySingleton<UsageService>(() => svc);
    await svc.logUsage(
      UsageLog(
        id: '1',
        timestamp: DateTime.now(),
        providerId: 'gemini',
        modelName: 'gemini-2.5-flash',
        latencyMs: 100,
        estimatedTokens: 40,
        isSuccess: true,
      ),
    );
    await svc.logUsage(
      UsageLog(
        id: '2',
        timestamp: DateTime.now(),
        providerId: 'groq',
        modelName: 'llama-3.3-70b',
        latencyMs: 5,
        estimatedTokens: 10,
        isSuccess: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [usageNotifierProvider.overrideWith(UsageNotifier.new)],
        child: const MaterialApp(home: SessionListScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Gemini'));
    await tester.pump();
    expect(find.text('gemini • gemini-2.5-flash'), findsOneWidget);
    expect(find.text('groq • llama-3.3-70b'), findsNothing);

    await svc.clearLogs();
    await tester.pump();
    expect(find.text('No Sessions Yet'), findsOneWidget);
  });
}
