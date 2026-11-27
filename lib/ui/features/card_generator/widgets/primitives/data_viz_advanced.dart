import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Advanced manual-entry data-viz modules. Each accepts compact text input so
/// it works without a live data source.
abstract final class DataVizInput {
  static List<int> integers(String raw) => raw
      .split(RegExp(r'[,;\s]+'))
      .map((p) => int.tryParse(p.trim()))
      .whereType<int>()
      .toList();

  static List<double> decimals(String raw) => raw
      .split(RegExp(r'[,;\s]+'))
      .map((p) => double.tryParse(p.trim()))
      .whereType<double>()
      .map((v) => v.clamp(0.0, 1.0))
      .toList();

  static List<double> xgPoints(String raw) => raw
      .split(RegExp(r'[,;\s]+'))
      .map((p) => p.split(':'))
      .where((parts) => parts.length == 2)
      .map((parts) => double.tryParse(parts[1].trim()))
      .whereType<double>()
      .toList();

  static List<Shot> shots(String raw) => raw
      .split(';')
      .map((p) => p.split(','))
      .where((parts) => parts.length >= 3)
      .map(
        (parts) => Shot(
          x: (double.tryParse(parts[0].trim()) ?? 0.5).clamp(0.0, 1.0),
          y: (double.tryParse(parts[1].trim()) ?? 0.5).clamp(0.0, 1.0),
          xg: (double.tryParse(parts[2].trim()) ?? 0.1).clamp(0.0, 1.0),
          isGoal: parts.length > 3 && parts[3].trim().toLowerCase() == 'goal',
        ),
      )
      .toList();
}

class Shot {
  const Shot({
    required this.x,
    required this.y,
    required this.xg,
    required this.isGoal,
  });

  final double x;
  final double y;
  final double xg;
  final bool isGoal;
}

class BumpChart extends StatelessWidget {
  const BumpChart({super.key, required this.positions, this.height = 80});

  final String positions;
  final double height;

  @override
  Widget build(BuildContext context) {
    final values = DataVizInput.integers(positions);
    if (values.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: CustomPaint(painter: _BumpPainter(values), size: Size.infinite),
    );
  }
}

class _BumpPainter extends CustomPainter {
  const _BumpPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final max = values.reduce((a, b) => a > b ? a : b).clamp(1, 20);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * size.width / (values.length - 1),
          size.height - (values[i] / max) * size.height,
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (final p in points) {
      canvas.drawCircle(p, 3, Paint()..color = const Color(0xFFFFB020));
    }
  }

  @override
  bool shouldRepaint(covariant _BumpPainter old) => old.values != values;
}

class RadarChart extends StatelessWidget {
  const RadarChart({super.key, required this.metrics, this.size = 120});

  final String metrics;
  final double size;

  @override
  Widget build(BuildContext context) {
    final values = DataVizInput.decimals(metrics);
    if (values.length < 3) return const SizedBox.shrink();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RadarPainter(values), size: Size.infinite),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final grid = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke;
    for (final ring in [0.33, 0.66, 1.0]) {
      canvas.drawCircle(center, radius * ring, grid);
    }

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          center.dx +
              radius *
                  values[i] *
                  math.cos(2 * math.pi * i / values.length - math.pi / 2),
          center.dy +
              radius *
                  values[i] *
                  math.sin(2 * math.pi * i / values.length - math.pi / 2),
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFB020).withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFB020)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.values != values;
}

class XgTimeline extends StatelessWidget {
  const XgTimeline({super.key, required this.points, this.height = 80});

  final String points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final values = DataVizInput.xgPoints(points);
    if (values.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: CustomPaint(painter: _XgPainter(values), size: Size.infinite),
    );
  }
}

class _XgPainter extends CustomPainter {
  const _XgPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final cumulative = <double>[0];
    for (final v in values) {
      cumulative.add(cumulative.last + v);
    }
    final max = cumulative.last.clamp(0.1, double.infinity);
    final path = Path();
    for (var i = 0; i < cumulative.length; i++) {
      final x = i * size.width / (cumulative.length - 1);
      final y = size.height - (cumulative[i] / max) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF32D74B)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _XgPainter old) => old.values != values;
}

class ShotMap extends StatelessWidget {
  const ShotMap({super.key, required this.shots, this.height = 120});

  final String shots;
  final double height;

  @override
  Widget build(BuildContext context) {
    final values = DataVizInput.shots(shots);
    if (values.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: CustomPaint(painter: ShotPainter(values), size: Size.infinite),
    );
  }
}

class ShotPainter extends CustomPainter {
  const ShotPainter(this.shots);

  final List<Shot> shots;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke,
    );
    for (final shot in shots) {
      canvas.drawCircle(
        Offset(shot.x * size.width, shot.y * size.height),
        3 + shot.xg * 9,
        Paint()
          ..color = shot.isGoal
              ? const Color(0xFF32D74B)
              : const Color(0xFFFF453A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ShotPainter old) => old.shots != shots;
}
