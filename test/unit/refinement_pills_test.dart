import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/error/failures.dart';
import 'package:oreamnos/core/repositories/content_repository.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/models/custom_pill.dart';
import 'package:oreamnos/domain/models/default_pill.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'package:oreamnos/ui/core/widgets/refinement_pill.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_state.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DefaultPills', () {
    test('contains expected standard refinement actions', () {
      expect(kDefaultRefinementPills.length, 10);
      final ids = kDefaultRefinementPills.map((p) => p.id).toSet();
      expect(ids.length, 10);
      expect(ids, contains('default_rephrase'));
      expect(ids, contains('default_check_flow'));
      expect(ids, contains('default_shorter'));
      expect(ids, contains('default_bullet_points'));
      expect(ids, contains('default_sports_stats'));
      expect(ids, contains('default_sports_post'));
      expect(ids, contains('default_split_paragraphs'));
      expect(ids, contains('default_restructure'));
      expect(ids, contains('default_grammar_check'));
      expect(ids, contains('default_fix_translation'));

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

    testWidgets(
      'shows checkmark icon and selected state when isSelected is true',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RefinementPill(
                label: 'Selected Pill',
                icon: Icons.star_rounded,
                isSelected: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(find.byIcon(Icons.star_rounded), findsNothing);
      },
    );
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

  group('GenerateUiState - selectedPillIds', () {
    test('defaults to empty set and can be updated via copyWith', () {
      const state = GenerateUiState();
      expect(state.selectedPillIds, isEmpty);

      final updated = state.copyWith(selectedPillIds: {'pill-1', 'pill-2'});
      expect(updated.selectedPillIds, containsAll(['pill-1', 'pill-2']));
      expect(updated.selectedPillIds.length, 2);

      final cleared = updated.copyWith(selectedPillIds: const {});
      expect(cleared.selectedPillIds, isEmpty);
    });
  });

  group('GenerateViewModel - Pill Multi-Selection', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final prefService = PreferencesService(
        prefs: prefs,
        secureStorage: storage,
      );

      await getIt.reset();
      await configureDependencies();
      getIt.allowReassignment = true;
      getIt.registerLazySingleton<PreferencesService>(() => prefService);
      getIt.registerLazySingleton<UsageService>(() => UsageService(prefs));
      getIt.registerLazySingleton<LogService>(() => LogService(prefs));

      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      container.dispose();
    });

    test('togglePillSelection and clearPillSelection manage selected IDs', () {
      final notifier = container.read(generateViewModelProvider.notifier);

      expect(
        container.read(generateViewModelProvider).selectedPillIds,
        isEmpty,
      );

      // Select pill 1
      notifier.togglePillSelection('pill-1');
      expect(container.read(generateViewModelProvider).selectedPillIds, {
        'pill-1',
      });

      // Select pill 2
      notifier.togglePillSelection('pill-2');
      expect(container.read(generateViewModelProvider).selectedPillIds, {
        'pill-1',
        'pill-2',
      });

      // Deselect pill 1
      notifier.togglePillSelection('pill-1');
      expect(container.read(generateViewModelProvider).selectedPillIds, {
        'pill-2',
      });

      // Clear all selections
      notifier.clearPillSelection();
      expect(
        container.read(generateViewModelProvider).selectedPillIds,
        isEmpty,
      );
    });

    test('refineSelectedPills combines all instructions and clears selection on success', () async {
      final fakeRepo = _FakeContentRepository();
      final overrideContainer = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(overrideContainer.dispose);

      // Setup API key and initial post
      final settings = overrideContainer.read(
        settingsViewModelProvider.notifier,
      );
      await settings.setSelectedProvider(AiProvider.gemini);
      await settings.setSelectedModel('gemini-1.5-flash');
      await settings.setApiKey(AiProvider.gemini, 'fake-gemini-key');

      final notifier = overrideContainer.read(
        generateViewModelProvider.notifier,
      );

      // Generate an initial post
      await notifier.generatePost('Initial text');
      expect(overrideContainer.read(generateViewModelProvider).hasPost, isTrue);

      // Select two pills
      notifier.togglePillSelection('default_rephrase');
      notifier.togglePillSelection('default_shorter');
      expect(
        overrideContainer.read(generateViewModelProvider).selectedPillIds,
        {'default_rephrase', 'default_shorter'},
      );

      // Refine with selected pills
      final pillMap = {
        for (final p in kDefaultRefinementPills) p.id: p.instruction,
      };
      await notifier.refineSelectedPills(pillMap);

      final postState = overrideContainer.read(generateViewModelProvider);
      expect(postState.status, GenerateState.success);
      expect(fakeRepo.lastRefinements.length, 2);
      expect(
        fakeRepo.lastRefinements,
        contains(kDefaultRefinementPills[0].instruction),
      );
      expect(
        fakeRepo.lastRefinements,
        contains(kDefaultRefinementPills[2].instruction),
      );

      // Selections MUST be cleared upon success
      expect(postState.selectedPillIds, isEmpty);
    });
  });
}

class _FakeContentRepository implements IContentRepository {
  List<String> lastRefinements = [];

  @override
  Future<Result<CuratedPost>> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    required AiProvider provider,
    List<String> searchSources = const [],
    bool keepStructure = false,
    bool isFanModeEnabled = false,
    String fanClubName = '',
    String length = 'medium',
    String? siteName,
    String? authorDisplayName,
    String? candidateOutlet,
    bool isTwitter = false,
  }) async {
    return const ResultSuccess(
      CuratedPost(
        title: 'Initial Title',
        bodyMarkdown: 'Initial Body',
        hashtags: ['Tag'],
        source: SourceAttribution(label: 'source'),
        rawMarkdown: 'Raw',
      ),
    );
  }

  @override
  Future<Result<CuratedPost>> refinePost({
    required CuratedPost original,
    required List<String> refinements,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    bool includeSource = true,
    bool keepStructure = false,
  }) async {
    lastRefinements = refinements;
    return ResultSuccess(
      original.copyWith(bodyMarkdown: 'Refined: ${refinements.join(", ")}'),
    );
  }

  @override
  Future<Result<String>> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    required String tone,
    required String defaultHashtags,
  }) async {
    return const ResultSuccess('Generated');
  }

  @override
  Future<Result<String>> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
  }) async {
    return const ResultSuccess('Rewritten');
  }
}
