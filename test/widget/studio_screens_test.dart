import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/club_profile_store.dart';
import 'package:oreamnos/data/services/export_service.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/carousel_slide.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_state.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/carousel_composer_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/views/carousel_composer_screen.dart';
import 'package:oreamnos/ui/features/settings/views/brand_kit_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    final prefs = await createMockPrefs();
    await getIt.reset();
    getIt.registerLazySingleton<ExportService>(() => ExportService());
    getIt.registerLazySingleton<ClubProfileStore>(
      () => ClubProfileStore(prefs),
    );
  });

  testWidgets('carousel screen shows a slide added to the composer', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cardGeneratorViewModelProvider.overrideWith(
            () => _FakeCardGeneratorViewModel(),
          ),
        ],
        child: const MaterialApp(home: CarouselComposerScreen()),
      ),
    );

    expect(
      find.text('Add up to 10 slides to build a carousel.'),
      findsOneWidget,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CarouselComposerScreen)),
    );
    container
        .read(carouselComposerProvider.notifier)
        .addSlide(
          const CarouselSlide(
            type: CarouselSlideType.cover,
            data: CardData.sparse(headline: 'Cover', subtext: ''),
          ),
        );
    await tester.pump();
    expect(find.textContaining('COVER'), findsOneWidget);
  });

  testWidgets('brand kit screen renders the club setup form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BrandKitScreen()));
    expect(find.text('Brand Kit'), findsOneWidget);
    expect(find.text('Kit colours'), findsOneWidget);
    expect(find.text('Add player'), findsOneWidget);
  });

  test('studio routes are registered', () {
    expect(RoutePaths.carousel, '/carousel');
    expect(RoutePaths.brandKit, '/brand-kit');
  });
}

class _FakeCardGeneratorViewModel extends CardGeneratorViewModel {
  _FakeCardGeneratorViewModel();

  @override
  CardGeneratorState build() => const CardGeneratorState();
}
