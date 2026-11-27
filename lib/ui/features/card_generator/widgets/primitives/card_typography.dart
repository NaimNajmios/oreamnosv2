import 'package:flutter/material.dart';

import '../../../../../config/theme/card_type.dart';

/// Backwards-compatible facade over the [CardType] five-tier system.
///
/// New renderers should use [CardType] directly; these helpers keep the older
/// scoreboard/quote/stat renderers compiling while they are migrated.
class CardTypography {
  const CardTypography._();

  /// HERO — the dominant focal element (score, player name, big fee).
  static TextStyle get hero => CardType.hero;

  /// HEADLINE — secondary large display text.
  static TextStyle get headline => CardType.display;

  /// TITLE — section titles and player names.
  static TextStyle title({
    Color? color,
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w700,
  }) => CardType.title.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );

  /// KICKER — small uppercase category label.
  static TextStyle kicker({Color? color, double fontSize = 13}) =>
      CardType.label.copyWith(
        color: color ?? const Color(0xB3FFFFFF),
        fontSize: fontSize,
        letterSpacing: 3.5,
      );

  /// BODY — supporting text or narrative quotes.
  static TextStyle body({
    Color? color,
    double fontSize = 16,
    FontStyle? fontStyle,
  }) => CardType.body.copyWith(
    color: color ?? const Color(0xCCFFFFFF),
    fontSize: fontSize,
    fontStyle: fontStyle,
  );

  /// META — timestamps, sources, attendance, bylines.
  static TextStyle meta({Color? color, double fontSize = 12}) =>
      CardType.label.copyWith(
        color: color ?? const Color(0x99FFFFFF),
        fontSize: fontSize,
        letterSpacing: 0.8,
      );
}
