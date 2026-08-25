import 'dart:math' as math;
import 'package:flutter/material.dart';

class KickoffLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const KickoffLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<KickoffLoadingIndicator> createState() => _KickoffLoadingIndicatorState();
}

class _KickoffLoadingIndicatorState extends State<KickoffLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // The original SVG animateTransform dur="2.4s"
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Default Adaptive Theming:
    // In light mode: background disc is dark (onSurface), elements are light (surface)
    // In dark mode: background disc is light (onSurface), elements are dark (surface)
    final resolvedBackgroundColor = widget.backgroundColor ?? colorScheme.onSurface;
    final resolvedForegroundColor = widget.foregroundColor ?? colorScheme.surface;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: KickoffLoadingPainter(
              animationValue: _controller.value,
              backgroundColor: resolvedBackgroundColor,
              foregroundColor: resolvedForegroundColor,
            ),
          );
        },
      ),
    );
  }
}

class KickoffLoadingPainter extends CustomPainter {
  final double animationValue;
  final Color backgroundColor;
  final Color foregroundColor;

  KickoffLoadingPainter({
    required this.animationValue,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The original SVG has a 512x512 viewBox. Scale canvas down to widget size.
    final scale = size.width / 512.0;
    canvas.scale(scale, scale);

    const center = Offset(256.0, 256.0);

    // 1. Draw outer background disc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 248.0, bgPaint);

    // 2. Draw static center elements
    final strokePaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    canvas.drawCircle(center, 56.0, strokePaint);

    final dotPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10.0, dotPaint);

    // 3. Draw rotating orbiting dots
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * 2 * math.pi); // Full rotation

    // 18 orbiting dots evenly spaced on a circle with radius 170
    for (int i = 0; i < 18; i++) {
      final angle = (i * 2 * math.pi) / 18.0;
      // Start mapping from top (-pi/2) to match exact original positioning
      final dx = 170.0 * math.cos(angle - math.pi / 2);
      final dy = 170.0 * math.sin(angle - math.pi / 2);
      canvas.drawCircle(Offset(dx, dy), 14.0, dotPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KickoffLoadingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.foregroundColor != foregroundColor;
  }
}
