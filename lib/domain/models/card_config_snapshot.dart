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
    this.watermarkImage,
    this.watermarkSize = 60.0,
    this.watermarkOffset = const Offset(0.85, 0.9),
    this.brandName,
    this.brandHandle,
    this.showBrandFooter = true,
    this.imagePosition = ImagePosition.background,
    this.photoFilter = PhotoFilter.none,
    this.imageOpacity = 1.0,
    this.backgroundBlurRadius = 0.0,
    this.badgeText,
    this.accentColor,
    this.previewScale = 1.0,
    this.backgroundType = BackgroundType.gradient,
    this.presetBackground,
    this.textShadowRadius = 0.0,
    this.textShadowColor,
    this.isGlowEnabled = false,
    this.headlineOffset = const Offset(0.5, 0.2),
    this.subtextOffset = const Offset(0.5, 0.5),
    this.microStatOffset = const Offset(0.5, 0.8),
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
  final File? watermarkImage;
  final double watermarkSize;
  final Offset watermarkOffset;
  final String? brandName;
  final String? brandHandle;
  final bool showBrandFooter;
  final ImagePosition imagePosition;
  final PhotoFilter photoFilter;
  final double imageOpacity;
  final double backgroundBlurRadius;
  final String? badgeText;
  final Color? accentColor;
  final double previewScale;
  final BackgroundType backgroundType;
  final PresetBackground? presetBackground;
  final double textShadowRadius;
  final Color? textShadowColor;
  final bool isGlowEnabled;
  final Offset headlineOffset;
  final Offset subtextOffset;
  final Offset microStatOffset;
}
