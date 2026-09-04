import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/custom_pill.dart';
import 'package:oreamnos/domain/models/default_pill.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'package:oreamnos/ui/core/widgets/refinement_pill.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_state.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DefaultPills', () {
    test('contains expected standard refinement actions', () {
      expect(kDefaultRefinementPills.length, 3);
      final ids = kDefaultRefinementPills.map((p) => p.id).toSet();
      expect(ids.length, 3);
      expect(ids, contains('default_rephrase'));
      expect(ids, contains('default_check_flow'));
      expect(ids, contains('default_shorter'));

      for (final pill in kDefaultRefinementPills) {
        expect(pill.label.isNotEmpty, isTrue);
        expect(pill.instruction.isNotEmpty, isTrue);
      }
    });
  });

  group('RefinementPill Widget', () {
    testWidgets('renders label and icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RefinementPill(label: 'Test Pill', icon: Icons.star_rounded),
          ),
        ),
      );

      expect(find.text('Test Pill'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets(
      'shows loading indicator and suppresses tap when isLoading is true',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RefinementPill(
                label: 'Loading Pill',
                isLoading: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.byType(KickoffLoadingIndicator), findsOneWidget);
        await tester.tap(find.byType(RefinementPill));
        expect(tapped, isFalse);
      },
    );

    testWidgets('suppresses tap when isDisabled is true', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefinementPill(
              label: 'Disabled Pill',
              isDisabled: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RefinementPill));
      expect(tapped, isFalse);
    });

    testWidgets('supports long press callback when enabled', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefinementPill(
              label: 'Editable Pill',
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(RefinementPill));
      expect(longPressed, isTrue);
    });
  });

  group('SettingsViewModel - Reorder Custom Pills', () {
    test('reorders custom pills correctly and persists them', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final prefService = createTestPreferencesService(prefs);

      // Initialize with test pills
      final pillA = CustomPill(id: '1', label: 'Pill A', instruction: 'Inst A');
      final pillB = CustomPill(id: '2', label: 'Pill B', instruction: 'Inst B');
      final pillC = CustomPill(id: '3', label: 'Pill C', instruction: 'Inst C');

      await prefService.setCustomPills([pillA, pillB, pillC]);

      if (getIt.isRegistered<PreferencesService>()) {
        getIt.unregister<PreferencesService>();
      }
      getIt.registerSingleton<PreferencesService>(prefService);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsViewModelProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        container
            .read(settingsViewModelProvider)
            .customPills
            .map((p) => p.label)
            .toList(),
        ['Pill A', 'Pill B', 'Pill C'],
      );

      // Move Pill A (index 0) to after Pill B (insertion index 1 in remaining list)
      await notifier.reorderCustomPills(0, 1);

      expect(
        container
            .read(settingsViewModelProvider)
            .customPills
            .map((p) => p.label)
            .toList(),
        ['Pill B', 'Pill A', 'Pill C'],
      );

      // Verify persisted state
      final saved = prefService.customPills;
      expect(saved.map((p) => p.label).toList(), [
        'Pill B',
        'Pill A',
        'Pill C',
      ]);

      // Out-of-bounds safety check
      await notifier.reorderCustomPills(-1, 5);
      expect(
        container
            .read(settingsViewModelProvider)
            .customPills
            .map((p) => p.label)
            .toList(),
        ['Pill B', 'Pill A', 'Pill C'],
      );
    });
  });

  group('GenerateUiState - activePillId', () {
    test('defaults to null and can be updated via copyWith', () {
      const state = GenerateUiState();
      expect(state.activePillId, isNull);

      final updated = state.copyWith(activePillId: 'pill-123');
      expect(updated.activePillId, 'pill-123');

      final cleared = updated.copyWith(activePillId: null);
      expect(cleared.activePillId, isNull);
    });
  });
}
