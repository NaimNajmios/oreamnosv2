import 'package:flutter/material.dart';

import 'card_template.dart';

enum BackgroundType { gradient, gallery, preset }

enum ImagePosition {
  background,
  splitLeft,
  splitRight,
  overlayTop,
  cutout,
  minimal,
  magazineBold,
  offsetCard,
  brutalist,
  floatWindow,
}

enum PhotoFilter { none, blackWhite, vintage, vibrant, highContrast }

enum ExportSize {
  square(1080, 1080),
  portrait(1080, 1350),
  story(1080, 1920);

  const ExportSize(this.width, this.height);
  final int width;
  final int height;
}

enum PresetBackground { stadiumBlur, darkMesh, grassTexture }

enum ScrimType { dark, light, minimal, none, horizontal, reverseHorizontal }

class CardConfig {
  final CardTemplate template;
  final BackgroundType backgroundType;
  final List<Color> colorPair;
  final ExportSize exportSize;
  final String? backgroundImagePath;
  final PresetBackground? presetBackground;
  final ImagePosition imagePosition;
  final double imageOpacity;
  final bool showScrim;
  final ScrimType scrimType;
  final String? cutoutPath;
  final double fontSizeMultiplier;
  final double overlayOpacity;
  final String? primaryFontFamilyName;
  final Color? accentColor;
  final Map<String, Offset> elementOffsets;
  final double backgroundBlurRadius;
  final String? watermarkPath;
  final double textShadowRadius;
  final Color textShadowColor;
  final bool isGlowEnabled;
  final PhotoFilter photoFilter;
  final double previewScale;
  final double watermarkSize;
  final bool isWatermarkEnabled;
  final String? badgeText;
  final bool useAutoPalette;

  const CardConfig({
    this.template = CardTemplate.detailedScoreboard,
    this.backgroundType = BackgroundType.gradient,
    this.colorPair = const [Color(0xFF1A237E), Color(0xFF0D47A1)],
    this.exportSize = ExportSize.square,
    this.backgroundImagePath,
    this.presetBackground,
    this.imagePosition = ImagePosition.background,
    this.imageOpacity = 1.0,
    this.showScrim = true,
    this.scrimType = ScrimType.dark,
    this.cutoutPath,
    this.fontSizeMultiplier = 1.0,
    this.overlayOpacity = 0.6,
    this.primaryFontFamilyName,
    this.accentColor,
    this.elementOffsets = const {},
    this.backgroundBlurRadius = 0,
    this.watermarkPath,
    this.textShadowRadius = 0,
    this.textShadowColor = const Color(0x80000000),
    this.isGlowEnabled = false,
    this.photoFilter = PhotoFilter.none,
    this.previewScale = 1.0,
    this.watermarkSize = 60,
    this.isWatermarkEnabled = true,
    this.badgeText,
    this.useAutoPalette = false,
  });

  CardConfig copyWith({
    CardTemplate? template,
    BackgroundType? backgroundType,
    List<Color>? colorPair,
    ExportSize? exportSize,
    String? backgroundImagePath,
    PresetBackground? presetBackground,
    ImagePosition? imagePosition,
    double? imageOpacity,
    bool? showScrim,
    ScrimType? scrimType,
    String? cutoutPath,
    double? fontSizeMultiplier,
    double? overlayOpacity,
    String? primaryFontFamilyName,
    Color? accentColor,
    Map<String, Offset>? elementOffsets,
    double? backgroundBlurRadius,
    String? watermarkPath,
    double? textShadowRadius,
    Color? textShadowColor,
    bool? isGlowEnabled,
    PhotoFilter? photoFilter,
    double? previewScale,
    double? watermarkSize,
    bool? isWatermarkEnabled,
    String? badgeText,
    bool? useAutoPalette,
  }) {
    return CardConfig(
      template: template ?? this.template,
      backgroundType: backgroundType ?? this.backgroundType,
      colorPair: colorPair ?? this.colorPair,
      exportSize: exportSize ?? this.exportSize,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      presetBackground: presetBackground ?? this.presetBackground,
      imagePosition: imagePosition ?? this.imagePosition,
      imageOpacity: imageOpacity ?? this.imageOpacity,
      showScrim: showScrim ?? this.showScrim,
      scrimType: scrimType ?? this.scrimType,
      cutoutPath: cutoutPath ?? this.cutoutPath,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      primaryFontFamilyName:
          primaryFontFamilyName ?? this.primaryFontFamilyName,
      accentColor: accentColor ?? this.accentColor,
      elementOffsets: elementOffsets ?? this.elementOffsets,
      backgroundBlurRadius: backgroundBlurRadius ?? this.backgroundBlurRadius,
      watermarkPath: watermarkPath ?? this.watermarkPath,
      textShadowRadius: textShadowRadius ?? this.textShadowRadius,
      textShadowColor: textShadowColor ?? this.textShadowColor,
      isGlowEnabled: isGlowEnabled ?? this.isGlowEnabled,
      photoFilter: photoFilter ?? this.photoFilter,
      previewScale: previewScale ?? this.previewScale,
      watermarkSize: watermarkSize ?? this.watermarkSize,
      isWatermarkEnabled: isWatermarkEnabled ?? this.isWatermarkEnabled,
      badgeText: badgeText ?? this.badgeText,
      useAutoPalette: useAutoPalette ?? this.useAutoPalette,
    );
  }

  // Helpers for clearing nullable fields
  CardConfig clearBackgroundImage() =>
      copyWith(backgroundImagePath: null, cutoutPath: null);
  CardConfig clearWatermark() => copyWith(watermarkPath: null);
}
