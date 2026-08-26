import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

import 'particles_painter.dart';

/// Serene Editorial success overlay with 25-particle radial explosion and animated checkmark.
class SuccessOverlay extends StatefulWidget {
  const SuccessOverlay({
    super.key,
    required this.onDismiss,
    this.message = 'Post Curated Successfully!',
  });

  final VoidCallback onDismiss;
  final String message;

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    Haptics.mediumImpact();
    _controller.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _initParticles() {
    final rand = math.Random();
    const colors = [
      AppColors.success,
      Color(0xFF34D399),
      Color(0xFF60A5FA),
      Color(0xFFFBBF24),
      Color(0xFFA78BFA),
    ];

    _particles = List.generate(25, (index) {
      final angle =
          (index / 25) * 2 * math.pi + (rand.nextDouble() * 0.2 - 0.1);
      final speed = 0.6 + rand.nextDouble() * 0.6;
      final size = 3.0 + rand.nextDouble() * 4.0;
      final color = colors[rand.nextInt(colors.length)];
      return Particle(angle: angle, speed: speed, size: size, color: color);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: InkWell(
        onTap: widget.onDismiss,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              // Particle progress 0.0 -> 1.0 during first 700ms
              final particleProgress = (val * 1.8).clamp(0.0, 1.0);
              // Scale pops up with spring curve
              final scale = val < 0.3
                  ? Curves.easeOutBack.transform(val / 0.3)
                  : (val > 0.85 ? 1.0 - (val - 0.85) / 0.15 * 0.2 : 1.0);
              // Checkmark draws from 0.2 -> 0.7
              final checkProgress = ((val - 0.2) / 0.5).clamp(0.0, 1.0);
              // Overall opacity
              final opacity = val > 0.85
                  ? (1.0 - (val - 0.85) / 0.15).clamp(0.0, 1.0)
                  : 1.0;

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial particles
                      CustomPaint(
                        size: const Size(220, 220),
                        painter: ParticlesPainter(
                          progress: particleProgress,
                          particles: _particles,
                        ),
                      ),
                      // Central Badge
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.25),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: AnimatedCheckmarkPainter(
                            progress: checkProgress,
                            color: AppColors.success,
                            strokeWidth: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
