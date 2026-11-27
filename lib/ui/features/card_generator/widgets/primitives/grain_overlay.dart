import 'package:flutter/material.dart';

/// Tiled film-grain overlay drawn inside the card's repaint boundary.
///
/// Uses a small bundled noise PNG rather than a fragment shader, so it behaves
/// identically on screen and in `RepaintBoundary.toImage` exports.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key, required this.child, this.strength = 0.55});

  final Widget child;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: strength.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/textures/grain.png'),
                    repeat: ImageRepeat.repeat,
                    fit: BoxFit.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
