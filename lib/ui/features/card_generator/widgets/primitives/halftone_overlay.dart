import 'package:flutter/material.dart';

/// Pre-rendered newsprint dot pattern for the tactile template family.
class HalftoneOverlay extends StatelessWidget {
  const HalftoneOverlay({super.key, required this.child, this.strength = 0.35});

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
                    image: AssetImage('assets/textures/halftone.png'),
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
