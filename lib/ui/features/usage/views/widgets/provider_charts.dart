import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/config/theme/app_typography.dart';
import 'package:oreamnos/domain/models/usage_log.dart';

/// Per-provider success donut (Android `SuccessRateChart` parity).
class SuccessRateDonut extends StatelessWidget {
  const SuccessRateDonut({super.key, required this.logs});

  final List<UsageLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final providers = <String>[];
    for (final l in logs) {
      final id = l.providerId.toLowerCase();
      if (!providers.contains(id)) providers.add(id);
    }
    if (providers.isEmpty) return const SizedBox.shrink();

    final total = logs.length;
    final success = logs.where((l) => l.isSuccess).length;
    final overall = total == 0 ? 0.0 : success / total;

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _DonutPainter(
                    segments: [
                      for (final p in providers)
                        _DonutSegment(
                          fraction:
                              logs
                                  .where((l) => l.providerId.toLowerCase() == p)
                                  .length /
                              total,
                          color: AppColors.tintForProvider(p, isDark),
                        ),
                    ],
                    trackColor: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(overall * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$success/$total',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in providers)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.tintForProvider(p, isDark),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p[0].toUpperCase() + p.substring(1),
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${_rate(logs, p).toStringAsFixed(0)}%',
                              style: AppTypography.mono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static double _rate(List<UsageLog> logs, String provider) {
    final mine = logs.where((l) => l.providerId.toLowerCase() == provider);
    if (mine.isEmpty) return 0;
    return mine.where((l) => l.isSuccess).length / mine.length * 100;
  }
}

class _DonutSegment {
  const _DonutSegment({required this.fraction, required this.color});
  final double fraction;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.trackColor});
  final List<_DonutSegment> segments;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawArc(rect.deflate(8), 0, math.pi * 2, false, track);
    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = s.fraction * math.pi * 2;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(8), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

/// Per-provider average latency bars with min/max + fastest/slowest badges
/// (Android `ResponseTimeChart` parity).
class ResponseTimeBars extends StatelessWidget {
  const ResponseTimeBars({super.key, required this.logs});

  final List<UsageLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final providers = <String>[];
    for (final l in logs) {
      final id = l.providerId.toLowerCase();
      if (!providers.contains(id)) providers.add(id);
    }
    if (providers.isEmpty) return const SizedBox.shrink();

    int globalMax = 1;
    final stats = <String, _LatencyStat>{};
    for (final p in providers) {
      final mine = logs.where((l) => l.providerId.toLowerCase() == p).toList();
      final lat = mine.map((l) => l.latencyMs).toList();
      final avg = lat.reduce((a, b) => a + b) ~/ lat.length;
      final min = lat.reduce(math.min);
      final max = lat.reduce(math.max);
      stats[p] = _LatencyStat(avg: avg, min: min, max: max, count: mine.length);
      if (avg > globalMax) globalMax = avg;
    }
    final fastest = stats.entries.reduce(
      (a, b) => a.value.avg < b.value.avg ? a : b,
    );
    final slowest = stats.entries.reduce(
      (a, b) => a.value.avg > b.value.avg ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in providers) ...[
          Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  p[0].toUpperCase() + p.substring(1),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats[p]!.avg / globalMax,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.35),
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.tintForProvider(p, isDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 118,
                child: Text(
                  '${stats[p]!.avg}ms ⌀ ${stats[p]!.min}/${stats[p]!.max}',
                  style: AppTypography.mono(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (p == fastest.key)
                _HighlightBadge(label: 'FASTEST', color: AppColors.success),
              if (p == slowest.key && slowest.key != fastest.key)
                _HighlightBadge(
                  label: 'SLOWEST',
                  color: theme.colorScheme.error,
                ),
            ],
          ),
          Text(
            '${stats[p]!.count} requests',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LatencyStat {
  const _LatencyStat({
    required this.avg,
    required this.min,
    required this.max,
    required this.count,
  });
  final int avg;
  final int min;
  final int max;
  final int count;
}

class _HighlightBadge extends StatelessWidget {
  const _HighlightBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
