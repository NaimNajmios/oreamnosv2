import 'package:flutter/material.dart';
import '../../../../../domain/models/usage_log.dart';

class UsageChart extends StatelessWidget {
  final List<UsageLog> logs;

  const UsageChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: CustomPaint(
        painter: _UsageChartPainter(
          logs: logs,
          lineColor: theme.colorScheme.primary,
          gridColor: theme.colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  final List<UsageLog> logs;
  final Color lineColor;
  final Color gridColor;

  _UsageChartPainter({
    required this.logs,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid
    const int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Prepare data points
    // We display chronologically, so reverse the logs (which are newest first)
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
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();
    
    for (int i = 0; i < reversedLogs.length; i++) {
      final log = reversedLogs[i];
      // Map x from 0 to width
      final x = reversedLogs.length == 1 
          ? size.width / 2 
          : (i / (reversedLogs.length - 1)) * size.width;
          
      // Map y from height to 0
      final y = size.height - (log.estimatedTokens / maxTokens * size.height * 0.9);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return oldDelegate.logs != logs ||
           oldDelegate.lineColor != lineColor ||
           oldDelegate.gridColor != gridColor;
  }
}
