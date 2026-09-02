import 'package:flutter/material.dart';

/// Soft radial light placed behind focal subjects (e.g. crest, player, hero numbers).
class SubjectGlow extends StatelessWidget {
  const SubjectGlow({
    super.key,
    this.color = const Color(0x40FFFFFF),
    this.size = 320,
    this.child,
  });

  final Color color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
