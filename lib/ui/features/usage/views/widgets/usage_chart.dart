import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/usage_log.dart';

/// Serene gradient line chart for token usage history.
class UsageChart extends StatelessWidget {
  final List<UsageLog> logs;

  const UsageChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: CustomPaint(
        painter: _UsageChartPainter(
          logs: logs,
          lineColor: theme.colorScheme.primary,
          fillColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          gridColor: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  final List<UsageLog> logs;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  _UsageChartPainter({
    required this.logs,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal hairline gridlines
    const int gridLines = 3;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final reversedLogs = logs.reversed.toList();

    int maxTokens = 1;
    for (var log in reversedLogs) {
      if (log.estimatedTokens > maxTokens) {
        maxTokens = log.estimatedTokens;
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();

    final points = <Offset>[];

    for (int i = 0; i < reversedLogs.length; i++) {
      final log = reversedLogs[i];
      final x = reversedLogs.length == 1
          ? size.width / 2
          : (i / (reversedLogs.length - 1)) * size.width;

      final y = size.height - (log.estimatedTokens / maxTokens * (size.height * 0.85)) - 4;
      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    if (points.isNotEmpty) {
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, linePaint);

      for (var point in points) {
        canvas.drawCircle(point, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return oldDelegate.logs != logs ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
