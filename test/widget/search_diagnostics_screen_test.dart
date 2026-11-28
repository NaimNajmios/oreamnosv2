import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/search_diagnostics_service.dart';
import 'package:oreamnos/domain/models/research_context.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_state.dart';
import 'package:oreamnos/ui/features/settings/views/search_diagnostics_screen.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    getIt.reset();
    getIt.allowReassignment = true;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SearchDiagnosticsScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows an empty state and recorded runs with guard decisions', (
    tester,
  ) async {
    final service = SearchDiagnosticsService();
    getIt.registerLazySingleton<SearchDiagnosticsRecorder>(() => service);
    final container = ProviderContainer(
      overrides: [
        settingsViewModelProvider.overrideWith(_FakeSettingsNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await pumpScreen(tester, container);

    expect(find.text('Web search diagnostics'), findsOneWidget);
    expect(find.textContaining('No research runs yet'), findsOneWidget);

    service.record(
      SearchDiagnosticEntry(
        at: DateTime(2026, 11, 28, 10, 30),
        status: ResearchStatus.ok,
        query: 'JDT beat Selangor 2-1',
        intent: 'result',
        topic: 'general',
        resultCount: 3,
        keptCount: 1,
        credits: 1,
        message: '1 relevant source(s)',
        decisions: const [
          SearchDecisionDetail(
            title: 'JDT beat Selangor',
            keep: true,
            reason: 'relevant',
            score: 0.9,
          ),
          SearchDecisionDetail(
            title: 'Traffic update',
            keep: false,
            reason: 'no entity/headline overlap',
            score: 0.8,
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.text('JDT beat Selangor 2-1'), findsOneWidget);
    expect(find.textContaining('KEEP'), findsOneWidget);
    expect(find.textContaining('DROP'), findsOneWidget);
    expect(find.textContaining('1/3 kept'), findsOneWidget);
  });
}
