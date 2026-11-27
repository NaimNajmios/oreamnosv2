import 'package:flutter/material.dart';

import 'card_fonts.dart';

/// The five type tiers used by every card renderer.
///
/// Only the two largest tiers use the Big Shoulders Display hero face; the
/// remaining tiers use the bundled Inter text face. All score/stat numerals
/// request tabular figures.
abstract final class CardType {
  static final List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// 96–120 on the 380dp design canvas: score, surname, big number.
  static TextStyle get hero => CardFonts.bigShouldersDisplay(
    fontSize: 112,
    fontWeight: FontWeight.w900,
    height: 0.9,
    letterSpacing: 1,
  ).copyWith(fontFeatures: tabular);

  /// 44–56: headline, quote, team names.
  static TextStyle get display => CardFonts.bigShouldersDisplay(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    height: 0.96,
    letterSpacing: 0.5,
  ).copyWith(fontFeatures: tabular);

  /// 24–28: section titles and player names.
  static TextStyle get title =>
      CardFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, height: 1.1);

  /// 16: supporting text.
  static TextStyle get body =>
      CardFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4);

  /// 12–13 minimum: kickers, meta and footers.
  static TextStyle get label => CardFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
  );

  /// Applies tabular numerals to any tier style.
  static TextStyle numeric(TextStyle style) =>
      style.copyWith(fontFeatures: tabular);

  /// Picks the tier whose design size is closest to [designFontSize].
  static TextStyle forSize(
    double designFontSize, {
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final tier = designFontSize >= 96
        ? hero
        : designFontSize >= 44
        ? display
        : designFontSize >= 24
        ? title
        : designFontSize >= 15
        ? body
        : label;
    return tier.copyWith(
      fontSize: designFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
