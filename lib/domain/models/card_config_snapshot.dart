import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

class CardConfigSnapshot {
  CardConfigSnapshot({
    this.cardData,
    required this.selectedTemplate,
    required this.selectedRatio,
    required this.selectedFont,
    required this.scrimOpacity,
    required this.useVignette,
    required this.headlineScale,
    required this.templateCompact,
    this.backgroundImage,
    required this.useAutoPalette,
    this.extractedPalette,
    this.watermarkText,
    this.showWatermark = false,
    this.brandName,
    this.brandHandle,
    this.showBrandFooter = true,
    this.imagePosition = ImagePosition.background,
    this.photoFilter = PhotoFilter.none,
  });

  final CardData? cardData;
  final CardTemplate selectedTemplate;
  final CardRatio selectedRatio;
  final AppFont selectedFont;
  final double scrimOpacity;
  final bool useVignette;
  final double headlineScale;
  final bool templateCompact;
  final File? backgroundImage;
  final bool useAutoPalette;
  final List<Color>? extractedPalette;
  final String? watermarkText;
  final bool showWatermark;
  final String? brandName;
  final String? brandHandle;
  final bool showBrandFooter;
  final ImagePosition imagePosition;
  final PhotoFilter photoFilter;
}
