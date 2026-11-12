import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/facebook_page_insights.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_banner.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_dialog.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_stat_line.dart';
import 'package:oreamnos/ui/features/publish/view_models/facebook_performance_view_model.dart';

/// Full performance view behind the Publish hub card.
class FacebookPerformanceScreen extends ConsumerStatefulWidget {
  const FacebookPerformanceScreen({super.key});

  @override
  ConsumerState<FacebookPerformanceScreen> createState() =>
      _FacebookPerformanceScreenState();
}

class _FacebookPerformanceScreenState
    extends ConsumerState<FacebookPerformanceScreen> {
  int _days = 28;

  @override
  void initState() {
    super.initState();
    _days = ref.read(facebookPerformanceProvider).days;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(facebookPerformanceProvider.notifier).ensureLoaded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(facebookPerformanceProvider);
    final connection = ref.watch(facebookViewModelProvider);
    final data = state.data;
    final points = _points(data);
    final posts = ref.watch(recentPublishedPostsProvider);
    final topPosts = ref.watch(facebookTopPostsProvider);
    final totals = data?.currentTotals;
    final previousTotals = data?.previousTotals;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Performance',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.loading
                ? null
                : () => ref
                      .read(facebookPerformanceProvider.notifier)
                      .refresh(days: _days),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(facebookPerformanceProvider.notifier)
              .refresh(days: _days);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                AppChip(
                  label: '7D',
                  selected: _days == 7,
                  onTap: () => _selectDays(7),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChip(
                  label: '28D',
                  selected: _days == 28,
                  onTap: () => _selectDays(28),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChip(
                  label: '90D',
                  selected: _days == 90,
                  onTap: () => _selectDays(90),
                ),
                const Spacer(),
                if (state.loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            if (connection.offline || connection.isExpired) ...[
              FacebookConnectionBanner(
                offline: connection.offline,
                expired: connection.isExpired,
                onRetry: () => ref
                    .read(facebookViewModelProvider.notifier)
                    .checkConnectionHealth(force: true),
                onReconnect: () => FacebookConnectionDialog.show(context),
              ),
              const SizedBox(height: AppSpacing.base),
            ],
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            else if (data != null && data.unavailableMetrics.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Some metrics are unavailable: '
                  '${data.unavailableMetrics.map(_metricLabel).join(', ')}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Media views',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _compact(
                      points.fold<int?>(
                        null,
                        (sum, p) => p.mediaViews == null
                            ? sum
                            : (sum ?? 0) + p.mediaViews!,
                      ),
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_deltaLabel(
                        totals?.mediaViews,
                        previousTotals?.mediaViews,
                      )
                      case final label?)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 140,
                    child: points.isEmpty
                        ? Center(
                            child: Text(
                              state.error != null ? 'Insights unavailable.' : 'No Page insights yet. Data can lag up to 24h.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Semantics(
                            label: _chartLabel(points),
                            child: ExcludeSemantics(
                              child: CustomPaint(
                                painter: _PerfChartPainter(
                                  points: points,
                                  lineColor: theme.colorScheme.primary,
                                  fillColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  gridColor: theme.colorScheme.outline
                                      .withValues(alpha: 0.3),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 380 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final cards = [
                  _KpiCard(
                    label: 'Engagements',
                    value: _compact(
                      points.fold<int?>(
                        null,
                        (sum, p) => p.engagements == null
                            ? sum
                            : (sum ?? 0) + p.engagements!,
                      ),
                    ),
                    delta: _deltaLabel(
                      totals?.engagements,
                      previousTotals?.engagements,
                    ),
                  ),
                  _KpiCard(
                    label: 'Followers',
                    value: _compact(_latestFollows(points)),
                    delta: _deltaLabel(
                      totals?.follows,
                      previousTotals?.follows,
                    ),
                  ),
                ];
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cards[0],
                      const SizedBox(height: AppSpacing.sm),
                      cards[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: cards[1]),
                  ],
                );
              },
            ),
            if (state.monetization != null && state.monetization!.hasAny) ...[
              const SizedBox(height: AppSpacing.base),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated earnings · 28 days',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(state.monetization!.totalEarnings),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Page currency · Meta can restate values. Payouts differ '
                      'because of reviews and copyright claims.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (topPosts.isNotEmpty) ...[
              Text(
                'Top posts · $_days days',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (final record in topPosts.take(3))
                      _PostRow(record: record),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              'Recent posts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (posts.isEmpty)
              AppCard(
                child: Text(
                  'Publish a post to see its engagement here.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (final record in posts) _PostRow(record: record),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<PageInsightPoint> _points(FacebookPageInsights? data) {
    if (data == null) return const [];
    final cutoff = DateTime.now().subtract(Duration(days: _days));
    return data.points
        .where(
          (p) =>
              !p.day.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day)),
        )
        .toList(growable: false);
  }

  void _selectDays(int days) {
    if (_days == days) return;
    setState(() => _days = days);
    ref.read(facebookPerformanceProvider.notifier).refresh(days: days);
  }

  static String _metricLabel(String metric) {
    return switch (metric) {
      'page_media_view' => 'media views',
      'page_follows' => 'followers',
      'page_post_engagements' => 'engagements',
      _ => metric,
    };
  }

  static int? _latestFollows(List<PageInsightPoint> points) {
    for (final point in points.reversed) {
      if (point.follows != null) return point.follows;
    }
    return null;
  }

  String? _deltaLabel(int? current, int? previous) {
    if (current == null && previous == null) return null;
    if (previous == null) return 'No previous data';
    if (current == null) return 'No data for this period';
    if (previous == 0) {
      return current == 0
          ? 'No change vs previous $_days days'
          : 'New vs previous $_days days';
    }
    final percent = ((current - previous) / previous * 100).round();
    if (percent == 0) return 'No change vs previous $_days days';
    final arrow = percent > 0 ? '↑' : '↓';
    return '$arrow ${percent.abs()}% vs previous $_days days';
  }

  static String _compact(int? value) {
    if (value == null) return '—';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }

  static String _money(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(2);
  }

  String _chartLabel(List<PageInsightPoint> points) {
    final values = <({DateTime day, int value})>[];
    for (final point in points) {
      final value = point.mediaViews;
      if (value != null) values.add((day: point.day, value: value));
    }
    if (values.isEmpty) {
      return 'Media views over the last $_days days. No data yet.';
    }
    var total = 0;
    var best = values.first;
    for (final entry in values) {
      total += entry.value;
      if (entry.value > best.value) best = entry;
    }
    return 'Media views over the last $_days days. Total ${_compact(total)}. '
        'Best day ${best.day.month}/${best.day.day} with '
        '${_compact(best.value)}.';
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, this.delta});

  final String label;
  final String value;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (delta != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                delta!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  const _PostRow({required this.record});

  final FacebookPostRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = facebookStatsFor(record);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.public_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (stats.isEmpty)
                  Text(
                    'No insights yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FacebookStatLine(stats: stats),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfChartPainter extends CustomPainter {
  _PerfChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<PageInsightPoint> points;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points
        .map((p) => p.mediaViews)
        .whereType<int>()
        .toList(growable: false);
    if (values.length < 2) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    var maxValue = 1;
    for (final value in values) {
      if (value > maxValue) maxValue = value;
    }

    final line = Path();
    final fill = Path()..moveTo(0, size.height);
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i / (values.length - 1) * size.width;
      final y = size.height - (values[i] / maxValue) * (size.height * 0.85) - 4;
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
      fill.lineTo(x, y);
    }
    fill
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fill, Paint()..color = fillColor);
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PerfChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
