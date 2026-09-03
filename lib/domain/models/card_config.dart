import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  story(1080, 1920),
  wide(1920, 1080),
  photo34(1080, 1440);

  const ExportSize(this.width, this.height);
  final int width;
  final int height;

  static ExportSize fromRatioName(String ratioName) {
    if (ratioName.contains('square')) return ExportSize.square;
    if (ratioName.contains('story')) return ExportSize.story;
    if (ratioName.contains('wide')) return ExportSize.wide;
    if (ratioName.contains('photo34')) return ExportSize.photo34;
    return ExportSize.portrait;
  }
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
  final double fontSizeMultiplier;
  final double overlayOpacity;
  final String? primaryFontFamilyName;
  final Color? accentColor;
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
  final String? brandName;
  final String? brandHandle;
  final bool showBrandFooter;

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
    this.fontSizeMultiplier = 1.0,
    this.overlayOpacity = 0.6,
    this.primaryFontFamilyName,
    this.accentColor,
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
    this.brandName,
    this.brandHandle,
    this.showBrandFooter = true,
  });

  TextStyle font({
    required double fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
    bool applyMultiplier = true,
  }) {
    final family = primaryFontFamilyName ?? 'Inter';
    final scaledSize = applyMultiplier
        ? fontSize * fontSizeMultiplier
        : fontSize;
    return GoogleFonts.getFont(
      family,
      fontSize: scaledSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color ?? Colors.white,
      height: height,
      letterSpacing: letterSpacing,
      shadows:
          shadows ??
          (textShadowRadius > 0
              ? [
                  Shadow(
                    color: textShadowColor,
                    blurRadius: textShadowRadius,
                    offset: isGlowEnabled ? Offset.zero : const Offset(2, 2),
                  ),
                ]
              : null),
    );
  }

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
    double? fontSizeMultiplier,
    double? overlayOpacity,
    String? primaryFontFamilyName,
    Color? accentColor,
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
    String? brandName,
    String? brandHandle,
    bool? showBrandFooter,
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
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      primaryFontFamilyName:
          primaryFontFamilyName ?? this.primaryFontFamilyName,
      accentColor: accentColor ?? this.accentColor,
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
      brandName: brandName ?? this.brandName,
      brandHandle: brandHandle ?? this.brandHandle,
      showBrandFooter: showBrandFooter ?? this.showBrandFooter,
    );
  }

  // Helpers for clearing nullable fields
  CardConfig clearBackgroundImage() => copyWith(backgroundImagePath: null);
  CardConfig clearWatermark() => copyWith(watermarkPath: null);
}
