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
  ParticlesPainter({
    required this.progress,
    required this.particles,
  });

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
    final path = Path();
    final start = Offset(size.width * 0.28, size.height * 0.52);
    final mid = Offset(size.width * 0.44, size.height * 0.68);
    final end = Offset(size.width * 0.74, size.height * 0.36);

    path.moveTo(start.dx, start.dy);
    path.lineTo(mid.dx, mid.dy);
    path.lineTo(end.dx, end.dy);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLength = metrics.first.length;
    final currentLength = totalLength * progress.clamp(0.0, 1.0);
    final animatedPath = metrics.first.extractPath(0.0, currentLength);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(animatedPath, paint);
  }

  @override
  bool shouldRepaint(covariant AnimatedCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
