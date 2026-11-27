import 'package:flutter/foundation.dart';

import 'card_config.dart';
import 'card_data.dart';

enum CarouselSlideType { cover, stat, quote, cta }

@immutable
class CarouselSlide {
  const CarouselSlide({
    required this.type,
    required this.data,
    this.headlineOverride,
  });

  final CarouselSlideType type;
  final CardData data;
  final String? headlineOverride;

  CarouselSlide copyWith({String? headlineOverride}) => CarouselSlide(
    type: type,
    data: data,
    headlineOverride: headlineOverride ?? this.headlineOverride,
  );
}

@immutable
class CarouselComposerState {
  const CarouselComposerState({
    this.slides = const [],
    this.masterSize = ExportSize.portrait,
  });

  final List<CarouselSlide> slides;
  final ExportSize masterSize;

  CarouselComposerState copyWith({
    List<CarouselSlide>? slides,
    ExportSize? masterSize,
  }) => CarouselComposerState(
    slides: slides ?? this.slides,
    masterSize: masterSize ?? this.masterSize,
  );
}
