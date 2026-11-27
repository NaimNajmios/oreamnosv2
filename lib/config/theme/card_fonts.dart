import 'package:flutter/material.dart';

/// Bundled font families used by card renderers.
///
/// Every family here is declared in `pubspec.yaml` under `flutter.fonts`, and
/// the SIL Open Font License files ship alongside the TTFs in `assets/fonts/`.
/// Nothing in this class fetches a font at runtime.
abstract final class CardFonts {
  /// Variable display face â€” the single hero face for cards.
  static const String display = 'BigShouldersDisplay';

  /// Variable text face.
  static const String text = 'Inter';

  /// Optional serif face ( Studio Deck "classic serif" choice ).
  static const String serif = 'Lora';

  /// Optional monospaced face â€” also replaces the old JetBrains Mono labels.
  static const String mono = 'SpaceMono';

  static const Set<String> _variableFamilies = {display, text, serif};

  /// Maps legacy family names used by older config snapshots / renderers to a
  /// bundled family so restored snapshots never fall back to a system font.
  static String resolveFamily(String? requested) {
    switch (requested) {
      case null:
      case '':
      case 'Inter':
      case 'default':
      case 'defaultFont':
        return text;
      case 'Lora':
        return serif;
      case 'Space Mono':
      case 'SpaceMono':
      case 'JetBrains Mono':
      case 'jetBrainsMono':
        return mono;
      case 'BarlowCondensed':
      case 'BigShouldersDisplay':
      case 'Big Shoulders Display':
        return display;
      default:
        return text;
    }
  }

  /// Builds a [TextStyle] from a bundled family.
  ///
  /// [textStyle] is used as the base when present (mirrors the old
  /// `CardFonts.*(textStyle: ...)` call shape). Variable families get an
  /// explicit `wght` axis so `FontWeight` is honoured without synthesised bold,
  /// and Inter gets its optical-size axis driven by the effective font size.
  static TextStyle style({
    required String family,
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    final base = textStyle ?? const TextStyle();
    final effectiveFamily = resolveFamily(family);
    final effectiveSize = fontSize ?? base.fontSize;
    final effectiveWeight = fontWeight ?? base.fontWeight;

    final variations = <FontVariation>[...?base.fontVariations];
    void setVariation(FontVariation variation) {
      final index = variations.indexWhere((v) => v.axis == variation.axis);
      if (index == -1) {
        variations.add(variation);
      } else {
        variations[index] = variation;
      }
    }

    if (_variableFamilies.contains(effectiveFamily) &&
        effectiveWeight != null) {
      setVariation(FontVariation('wght', effectiveWeight.value.toDouble()));
    }
    if (effectiveFamily == text) {
      setVariation(
        FontVariation('opsz', (effectiveSize ?? 16).clamp(14.0, 32.0)),
      );
    }

    return base.copyWith(
      fontFamily: effectiveFamily,
      fontVariations: variations.isEmpty ? null : variations,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  /// Drop-in replacement for the old `CardFonts.getFont(family, ...)` call.
  static TextStyle getFont(
    String family, {
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return style(
      family: family,
      textStyle: textStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  static TextStyle inter({
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return style(
      family: text,
      textStyle: textStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  static TextStyle lora({
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return style(
      family: serif,
      textStyle: textStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  static TextStyle spaceMono({
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return style(
      family: mono,
      textStyle: textStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  /// Former label face. Now resolves to the bundled Space Mono so no label
  /// silently falls back to a system font when offline.
  static TextStyle jetBrainsMono({
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return inter(
      textStyle: textStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  static TextStyle bigShouldersDisplay({
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return style(
      family: display,
      textStyle: textStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }
}
