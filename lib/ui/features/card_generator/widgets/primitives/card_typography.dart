import 'package:flutter/material.dart';

/// Centralized typography scale for broadcast-grade card renderers.
class CardTypography {
  const CardTypography._();

  /// HERO — the dominant focal element (e.g. score, player name, big fee).
  static const TextStyle hero = TextStyle(
    fontFamily: 'BarlowCondensed',
    fontWeight: FontWeight.w900,
    fontSize: 96,
    height: 0.95,
    letterSpacing: 1,
    color: Color(0xFFFFFFFF),
  );

  /// HEADLINE — secondary large display text.
  static const TextStyle headline = TextStyle(
    fontFamily: 'BarlowCondensed',
    fontWeight: FontWeight.w700,
    fontSize: 44,
    height: 1.0,
    letterSpacing: 0.5,
    color: Color(0xFFFFFFFF),
  );

  /// KICKER — small uppercase category label ("BREAKING NEWS", "TRANSFER ALERT").
  static TextStyle kicker({Color? color, double fontSize = 13}) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: fontSize,
    letterSpacing: 3.5,
    color: color ?? const Color(0xB3FFFFFF),
  );

  /// BODY — supporting text or narrative quotes.
  static TextStyle body({
    Color? color,
    double fontSize = 16,
    FontStyle? fontStyle,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: fontSize,
    fontStyle: fontStyle,
    height: 1.4,
    color: color ?? const Color(0xCCFFFFFF),
  );

  /// META — timestamps, sources, attendance, bylines.
  static TextStyle meta({Color? color, double fontSize = 12}) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: fontSize,
    letterSpacing: 0.8,
    color: color ?? const Color(0x99FFFFFF),
  );
}
