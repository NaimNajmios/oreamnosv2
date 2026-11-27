import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide CardTheme;
import 'package:oreamnos/config/theme/card_theme.dart';
import 'package:oreamnos/config/theme/card_type.dart';

/// Deterministic painter-based card layout snapshot.
///
/// Widget-level capture deadlocks under the fake-async test binding and
/// `alchemist 0.7` cannot compile on Flutter 3.47, so goldens exercise the
/// same type/colour tokens through [CustomPainter] instead.
class CardGoldenPainter extends CustomPainter {
  const CardGoldenPainter({
    required this.kicker,
    required this.hero,
    required this.template,
    this.accent = CardTheme.warningColor,
  });

  final String kicker;
  final String hero;
  final String template;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final theme = CardTheme.from(colorPair: [accent, accent]);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [theme.surface, theme.bg],
        ),
    );

    canvas.drawRect(Rect.fromLTWH(20, 20, 4, 18), Paint()..color = accent);

    _text(
      canvas,
      kicker.toUpperCase(),
      CardType.label.copyWith(fontSize: 12, color: accent, letterSpacing: 3),
      Offset(32, 18),
      size.width - 52,
    );
    _text(
      canvas,
      hero,
      CardType.hero.copyWith(fontSize: 64, color: Colors.white),
      Offset(20, size.height * 0.38),
      size.width - 40,
    );
    _text(
      canvas,
      template.toUpperCase(),
      CardType.label.copyWith(fontSize: 10, color: Colors.white60),
      Offset(20, size.height - 32),
      size.width - 40,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    TextStyle style,
    Offset offset,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CardGoldenPainter old) =>
      old.kicker != kicker || old.hero != hero || old.template != template;
}
