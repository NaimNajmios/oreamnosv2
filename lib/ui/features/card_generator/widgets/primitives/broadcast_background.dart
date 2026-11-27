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
    this.vignetteStrength = 0.2,
  });

  final CardConfig config;
  final Widget child;
  final double vignetteStrength;

  @override
  Widget build(BuildContext context) {
    final theme = config.theme;
    final hasCustomImage = config.backgroundImagePath != null;

    return Container(
      decoration: BoxDecoration(
        gradient: hasCustomImage
            ? null
            : GradientBuilder.diagonal([theme.surface, theme.bg]),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Flat, team-tinted surface — no radial glow.
          if (!hasCustomImage)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),

          // Edge framing (kept subtle).
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
