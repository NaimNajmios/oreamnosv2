import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/domain/models/carousel_slide.dart';

final carouselComposerProvider =
    NotifierProvider<CarouselComposer, CarouselComposerState>(
      CarouselComposer.new,
    );

/// Builds up to ten slides whose first slide's ratio is the master for all.
class CarouselComposer extends Notifier<CarouselComposerState> {
  static const int maxSlides = 10;

  @override
  CarouselComposerState build() => const CarouselComposerState();

  void setMasterSize(ExportSize size) {
    state = state.copyWith(masterSize: size);
  }

  bool addSlide(CarouselSlide slide) {
    if (state.slides.length >= maxSlides) return false;
    state = state.copyWith(slides: [...state.slides, slide]);
    return true;
  }

  void removeSlide(int index) {
    if (index < 0 || index >= state.slides.length) return;
    final slides = [...state.slides]..removeAt(index);
    state = state.copyWith(slides: slides);
  }

  void moveSlide(int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= state.slides.length ||
        to >= state.slides.length) {
      return;
    }
    final slides = [...state.slides];
    final slide = slides.removeAt(from);
    slides.insert(to, slide);
    state = state.copyWith(slides: slides);
  }

  void clear() => state = state.copyWith(slides: const []);
}
