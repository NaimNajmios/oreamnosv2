import 'dart:math' as math;

import 'package:flutter/material.dart';

class Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class ParticlesPainter extends CustomPainter {
  ParticlesPainter({required this.progress, required this.particles});

  final double progress;
  final List<Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (final p in particles) {
      final distance = p.speed * maxRadius * progress;
      final x = center.dx + math.cos(p.angle) * distance;
      final y = center.dy + math.sin(p.angle) * distance;

      final currentSize = p.size * (1.0 - (progress * 0.7));
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animated circle + check success mark (Android `AnimatedCheckmark` parity:
/// 400ms circle arc, 300ms check stroke, ease-out-back scale-in).
class AnimatedCheckmarkPainter extends CustomPainter {
  AnimatedCheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 5.0,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;

    // Scale-in with slight overshoot (ease-out-back approximation).
    final scale = p < 0.35
        ? (0.5 + 0.5 * (p / 0.35)) * (1 + 0.12 * math.sin(p / 0.35 * math.pi))
        : 1.0;
    final scaledRadius = radius * scale.clamp(0.0, 1.12);

    // Circle arc draws over the first 55% of progress.
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final circleSweep = ((p / 0.55).clamp(0.0, 1.0)) * math.pi * 2;
    if (circleSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: scaledRadius),
        -math.pi / 2,
        circleSweep,
        false,
        circlePaint,
      );
    }

    // Check stroke draws over the remaining progress.
    if (p > 0.4) {
      final checkProgress = ((p - 0.4) / 0.6).clamp(0.0, 1.0);
      final path = Path();
      final start = Offset(size.width * 0.30, size.height * 0.53);
      final mid = Offset(size.width * 0.45, size.height * 0.67);
      final end = Offset(size.width * 0.72, size.height * 0.37);
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);
      path.lineTo(end.dx, end.dy);

      final metrics = path.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final animatedPath = metrics.first.extractPath(
          0.0,
          metrics.first.length * checkProgress,
        );
        final checkPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(animatedPath, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
