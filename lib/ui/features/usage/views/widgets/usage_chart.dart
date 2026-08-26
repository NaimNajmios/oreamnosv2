import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          isDark: isDark,
          lineColor: theme.colorScheme.primary,
          fillColor: AppColors.lightViolet.withValues(alpha: 0.12),
          gridColor: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  final List<UsageLog> logs;
  final bool isDark;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  _UsageChartPainter({
    required this.logs,
    required this.isDark,
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

    // subtle teal-tinted fill for flat colorful background
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();

    final points = <Offset>[];

    for (int i = 0; i < reversedLogs.length; i++) {
      final log = reversedLogs[i];
      final x = reversedLogs.length == 1
          ? size.width / 2
          : (i / (reversedLogs.length - 1)) * size.width;

      final y =
          size.height -
          (log.estimatedTokens / maxTokens * (size.height * 0.85)) -
          4;
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

      // Draw per-segment lines with provider hue, dots with success/fail
      for (int i = 0; i < points.length - 1; i++) {
        final providerColor = AppColors.tintForProvider(
          reversedLogs[i].providerId,
          isDark,
        );
        final segPaint = Paint()
          ..color = providerColor
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final segPath = Path()
          ..moveTo(points[i].dx, points[i].dy)
          ..lineTo(points[i + 1].dx, points[i + 1].dy);
        canvas.drawPath(segPath, segPaint);
      }
      for (int i = 0; i < points.length; i++) {
        final log = reversedLogs[i];
        final dotColor = log.isSuccess
            ? AppColors.tintForProvider(log.providerId, isDark)
            : AppColors.error;
        final outer = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;
        final inner = Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(points[i], 5, outer);
        canvas.drawCircle(points[i], 3.5, inner);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return oldDelegate.logs != logs ||
        oldDelegate.isDark != isDark ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
