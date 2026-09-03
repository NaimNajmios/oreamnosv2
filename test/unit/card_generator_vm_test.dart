import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CardGeneratorViewModel Tests', () {
    late ProviderContainer container;
    late CardGeneratorViewModel vm;

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

      container = ProviderContainer();
      vm = container.read(cardGeneratorViewModelProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has no undo/redo', () {
      final state = container.read(cardGeneratorViewModelProvider);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
      expect(state.undoStack, isEmpty);
      expect(state.redoStack, isEmpty);
    });

    test('updateHeadline creates snapshot and allows undo', () {
      vm.updateHeadline('Initial Title');
      var state = container.read(cardGeneratorViewModelProvider);
      expect(state.canUndo, isTrue);
      expect(state.canRedo, isFalse);
      expect(state.cardData, isA<SparseCard>());
      expect((state.cardData as SparseCard).headline, 'Initial Title');

      vm.updateHeadline('Second Title');
      state = container.read(cardGeneratorViewModelProvider);
      expect(state.undoStack.length, 2);
      expect((state.cardData as SparseCard).headline, 'Second Title');

      // Test undo
      vm.undo();
      state = container.read(cardGeneratorViewModelProvider);
      expect(state.canRedo, isTrue);
      expect((state.cardData as SparseCard).headline, 'Initial Title');

      // Test redo
      vm.redo();
      state = container.read(cardGeneratorViewModelProvider);
      expect((state.cardData as SparseCard).headline, 'Second Title');
    });

    test('undo stack caps at 50 snapshots', () {
      for (int i = 1; i <= 55; i++) {
        vm.updateHeadline('Title $i');
      }

      final state = container.read(cardGeneratorViewModelProvider);
      expect(state.undoStack.length, 50);
    });

    test('configuration setters update state and record undo history', () {
      vm.setTemplate(CardTemplate.breakingNews);
      expect(
        container.read(cardGeneratorViewModelProvider).selectedTemplate,
        CardTemplate.breakingNews,
      );
      expect(container.read(cardGeneratorViewModelProvider).canUndo, isTrue);

      vm.setRatio(CardRatio.story);
      expect(
        container.read(cardGeneratorViewModelProvider).selectedRatio,
        CardRatio.story,
      );

      vm.setImagePosition(ImagePosition.splitLeft);
      expect(
        container.read(cardGeneratorViewModelProvider).imagePosition,
        ImagePosition.splitLeft,
      );

      vm.setPhotoFilter(PhotoFilter.vintage);
      expect(
        container.read(cardGeneratorViewModelProvider).photoFilter,
        PhotoFilter.vintage,
      );

      vm.setHeadlineScale(1.1);
      expect(container.read(cardGeneratorViewModelProvider).headlineScale, 1.1);
    });

    test('updateCardField updates json-backed card data', () {
      // Set breaking news data
      vm.setTemplate(CardTemplate.breakingNews);
      vm.updateHeadline('Initial Breaking News');

      vm.updateCardField('subtext', 'Important context about the event');
      final state = container.read(cardGeneratorViewModelProvider);
      expect(state.cardData, isNotNull);
    });

    test('shuffleDesign randomizes visuals, keeps content, stays undoable', () {
      vm.updateHeadline('Keep me');
      final before = container.read(cardGeneratorViewModelProvider);
      vm.shuffleDesign();
      final after = container.read(cardGeneratorViewModelProvider);
      expect(after.cardData?.headline, before.cardData?.headline);
      expect(after.canUndo, isTrue);
      expect(after.backgroundType, BackgroundType.preset);
    });

    test('updateCardListField writes lineup rows with undo', () {
      vm.setTemplate(CardTemplate.startingXI);
      vm.updateCardListField('starters', [
        {'number': '1', 'name': 'Alisson'},
        {'number': '4', 'name': 'Van Dijk'},
      ]);
      final state = container.read(cardGeneratorViewModelProvider);
      final data = state.cardData;
      expect(data, isA<StartingXI>());
      expect((data as StartingXI).starters.length, 2);
      expect(data.starters.first.name, 'Alisson');
      expect(state.canUndo, isTrue);
    });

    test('setCardBoolField toggles verification flags', () {
      vm.setTemplate(CardTemplate.socialPost);
      vm.setCardBoolField('verified', true);
      final state = container.read(cardGeneratorViewModelProvider);
      expect((state.cardData as SocialPost).verified, isTrue);
    });
  });
}
