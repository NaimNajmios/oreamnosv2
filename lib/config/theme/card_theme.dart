import 'package:flutter/material.dart' hide CardTheme;

/// Which kit the card should follow (NBC-style uniform-led colour pairing).
enum KitMode { home, away, third }

/// Colour tokens shared by every card renderer.
///
/// The background is deliberately near-black, one saturated [accent] is
/// derived from the team/kit colours, and status colours are explicit tokens
/// rather than stock Material `xxxAccent` constants.
@immutable
class CardTheme {
  static const Color nearBlackBg = Color(0xFF0B0B0F);
  static const Color alertColor = Color(0xFFFF453A);
  static const Color warningColor = Color(0xFFFFB020);
  static const Color successColor = Color(0xFF32D74B);

  const CardTheme({
    required this.bg,
    required this.surface,
    required this.accent,
    required this.onBg,
    required this.teamPrimary,
    required this.teamSecondary,
    required this.kitColor,
    this.kitMode = KitMode.home,
  });

  final Color bg;
  final Color surface;
  final Color accent;
  final Color onBg;
  final Color teamPrimary;
  final Color teamSecondary;
  final Color kitColor;
  final KitMode kitMode;

  Color get alert => alertColor;
  Color get warning => warningColor;
  Color get success => successColor;

  factory CardTheme.from({
    required List<Color> colorPair,
    KitMode kitMode = KitMode.home,
    Color? accentOverride,
  }) {
    final primary = colorPair.isEmpty
        ? const Color(0xFF1A237E)
        : colorPair.first;
    final secondary = colorPair.length > 1 ? colorPair.last : primary;
    final kit = _kitColor(primary, secondary, kitMode);

    final kitHsv = HSVColor.fromColor(kit);
    final saturated = HSVColor.fromColor(kit)
        .withSaturation(kitHsv.saturation.clamp(0.75, 1.0).toDouble())
        .withValue(kitHsv.value.clamp(0.85, 1.0).toDouble());
    final accent = accentOverride ?? saturated.toColor();

    return CardTheme(
      bg: nearBlackBg,
      surface: Color.lerp(nearBlackBg, accent, 0.14)!,
      accent: accent,
      onBg: Colors.white,
      teamPrimary: primary,
      teamSecondary: secondary,
      kitColor: kit,
      kitMode: kitMode,
    );
  }

  static Color _kitColor(Color primary, Color secondary, KitMode mode) {
    return switch (mode) {
      KitMode.home => primary,
      KitMode.away => secondary,
      KitMode.third =>
        HSVColor.fromColor(primary)
            .withHue((HSVColor.fromColor(primary).hue + 180) % 360)
            .withSaturation(0.65)
            .toColor(),
    };
  }
}
