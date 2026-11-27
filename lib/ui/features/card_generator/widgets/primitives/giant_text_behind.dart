import 'package:flutter/material.dart' hide CardTheme;

import '../../../../../config/theme/card_fonts.dart';
import '../../../../../config/theme/card_theme.dart';

/// Giant outlined type layered behind a user-supplied cutout.
///
/// Layer order is background → this text → [child] cutout → foreground card
/// content. The text is decorative, so it is hidden from semantics.
class GiantTextBehind extends StatelessWidget {
  const GiantTextBehind({
    super.key,
    required this.text,
    required this.child,
    this.color,
    this.fontSize = 140,
    this.strokeWidth = 2,
  });

  final String text;
  final Widget child;
  final Color? color;
  final double fontSize;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final stroke = color ?? CardTheme.warningColor;
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Center(
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: CardFonts.display,
                  fontWeight: FontWeight.w900,
                  fontSize: fontSize,
                  letterSpacing: -2,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeWidth
                    ..color = stroke.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
        Center(child: child),
      ],
    );
  }
}
