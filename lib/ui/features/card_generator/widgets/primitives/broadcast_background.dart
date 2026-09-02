import 'package:flutter/material.dart';

import '../../../../../data/services/gradient_builder.dart';
import '../../../../../domain/models/card_config.dart';
import 'vignette.dart';

/// Layered broadcast background providing dimensional light:
/// 1. Base gradient (diagonal)
/// 2. Top-left radial accent light
/// 3. Vignette edge framing
/// 4. Dynamic scrim (if enabled)
/// 5. Foreground content
class BroadcastBackground extends StatelessWidget {
  const BroadcastBackground({
    super.key,
    required this.config,
    required this.child,
    this.vignetteStrength = 0.5,
  });

  final CardConfig config;
  final Widget child;
  final double vignetteStrength;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final hasCustomImage = config.backgroundImagePath != null;

    return Container(
      decoration: BoxDecoration(
        gradient: hasCustomImage ? null : GradientBuilder.diagonal(colors),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 2: Top-left radial accent light (creates depth/specular glow)
          if (!hasCustomImage && colors.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.6, -0.7),
                      radius: 1.25,
                      colors: [
                        colors.first.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // Layer 3: Edge vignette
          Vignette(strength: vignetteStrength),

          // Layer 4: Scrim
          if (config.showScrim)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: GradientBuilder.scrimFor(
                      config.scrimType,
                      config.overlayOpacity,
                    ),
                  ),
                ),
              ),
            ),

          // Layer 5: Foreground content
          child,
        ],
      ),
    );
  }
}
