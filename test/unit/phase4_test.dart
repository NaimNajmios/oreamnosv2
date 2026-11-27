import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/export_service.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/carousel_slide.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/carousel_composer_view_model.dart';

void main() {
  group('export sizing', () {
    test('pixel ratio produces exact 1080px wide output', () {
      for (final size in [
        ExportSize.square,
        ExportSize.portrait,
        ExportSize.story,
        ExportSize.photo34,
      ]) {
        expect(ExportService.pixelRatio(size) * 380, 1080);
      }
      expect(ExportService.pixelRatio(ExportSize.wide) * 380, 1920);
    });
  });

  group('carousel composer', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    CarouselComposer composer() =>
        container.read(carouselComposerProvider.notifier);

    CarouselSlide slide(int i) => CarouselSlide(
      type: CarouselSlideType.cover,
      data: CardData.sparse(headline: 'Slide $i', subtext: ''),
    );

    test('caps slides at ten', () {
      for (var i = 0; i < 12; i++) {
        composer().addSlide(slide(i));
      }
      expect(container.read(carouselComposerProvider).slides.length, 10);
    });

    test('reorders and removes slides', () {
      composer().addSlide(slide(1));
      composer().addSlide(slide(2));
      composer().moveSlide(0, 1);
      expect(
        container.read(carouselComposerProvider).slides.first.data.headline,
        'Slide 2',
      );
      composer().removeSlide(0);
      expect(container.read(carouselComposerProvider).slides.length, 1);
    });

    test('master ratio is shared by every slide', () {
      composer().setMasterSize(ExportSize.story);
      composer().addSlide(slide(1));
      expect(
        container.read(carouselComposerProvider).masterSize,
        ExportSize.story,
      );
    });
  });
}
