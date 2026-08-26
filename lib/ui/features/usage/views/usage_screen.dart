import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes/app_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../data/services/usage_service.dart';
import '../../../../domain/models/usage_log.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/app_chip.dart';
import 'widgets/usage_chart.dart';

/// Serene Editorial Usage & Analytics screen — grouped, filtered, responsive.
class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  String _filter = 'all';
  int _displayLimit = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usageService = ref.watch(usageServiceProvider);
    final logsAll = usageService.logs;
    final logs = _filter == 'all'
        ? logsAll
        : logsAll.where((l) => l.providerId.toLowerCase() == _filter).toList();

    int totalTokens = 0;
    int successCount = 0;
    int totalLatency = 0;

    for (var log in logs) {
      totalTokens += log.estimatedTokens;
      if (log.isSuccess) successCount++;
      totalLatency += log.latencyMs;
    }

    final successRate = logs.isEmpty ? 0.0 : (successCount / logs.length) * 100;
    final avgLatency = logs.isEmpty ? 0 : totalLatency ~/ logs.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Usage & Analytics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.colorScheme.outline, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Session History',
            onPressed: () => context.push(RoutePaths.sessionHistory),
          ),
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear History',
              onPressed: () => _confirmClear(context, usageService),
            ),
        ],
      ),
      body: logs.isEmpty
          ? EmptyState(
              icon: Icons.analytics_outlined,
              title: 'No Usage Data Yet',
              description: 'Generated posts and API latency statistics will appear here.',
              iconColor: isDark ? AppColors.darkViolet : AppColors.lightViolet,
              iconBackground:
                  (isDark
                          ? AppColors.darkVioletSoft
                          : AppColors.lightVioletSoft)
                      .withValues(alpha: 0.35),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await usageService.reload();
                    Haptics.mediumImpact();
                  },
                  color: theme.colorScheme.primary,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.base,
                    ),
                    children: [
                      // 3 Metric StatCards — responsive, no truncation
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 380;
                          final tokensCard = StatCard(
                            title: 'Tokens',
                            value: NumberFormat.compact().format(totalTokens),
                            subtitle: '$totalTokens est.',
                            icon: Icons.data_usage_rounded,
                            iconColor: isDark
                                ? AppColors.darkTeal
                                : AppColors.lightTeal,
                            iconBackground:
                                (isDark
                                        ? AppColors.darkTealSoft
                                        : AppColors.lightTealSoft)
                                    .withValues(alpha: 0.6),
                            accentColor: isDark
                                ? AppColors.darkTeal
                                : AppColors.lightTeal,
                          );
                          final successCard = StatCard(
                            title: 'Success',
                            value: '${successRate.toStringAsFixed(0)}%',
                            subtitle: '$successCount / ${logs.length}',
                            icon: Icons.check_circle_outline_rounded,
                            valueColor: successRate >= 90
                                ? AppColors.success
                                : theme.colorScheme.primary,
                            iconColor: successRate >= 90
                                ? AppColors.success
                                : (isDark
                                      ? AppColors.darkViolet
                                      : AppColors.lightViolet),
                            iconBackground: successRate >= 90
                                ? AppColors.successSoft.withValues(alpha: 0.6)
                                : (isDark
                                          ? AppColors.darkVioletSoft
                                          : AppColors.lightVioletSoft)
                                      .withValues(alpha: 0.6),
                            accentColor: successRate >= 90
                                ? AppColors.success
                                : (isDark
                                      ? AppColors.darkViolet
                                      : AppColors.lightViolet),
                          );
                          final latencyCard = StatCard(
                            title: 'Avg Latency',
                            value: '${avgLatency}ms',
                            subtitle: 'Per prompt',
                            icon: Icons.speed_rounded,
                            iconColor: isDark
                                ? AppColors.darkAmber
                                : AppColors.lightAmber,
                            iconBackground:
                                (isDark
                                        ? AppColors.darkAmberSoft
                                        : AppColors.lightAmberSoft)
                                    .withValues(alpha: 0.6),
                            accentColor: isDark
                                ? AppColors.darkAmber
                                : AppColors.lightAmber,
                          );
                          if (isNarrow) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: successCard,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(child: tokensCard),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(child: latencyCard),
                                  ],
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: tokensCard),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: successCard),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: latencyCard),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.base),

                      // Usage Chart — grouped card with legend
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark
                                                ? AppColors.darkVioletSoft
                                                : AppColors.lightVioletSoft)
                                            .withValues(alpha: 0.35),
                                    borderRadius: AppSpacing.borderRadiusXs,
                                  ),
                                  child: Icon(
                                    Icons.show_chart_rounded,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.darkViolet
                                        : AppColors.lightViolet,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Token Usage History',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const Spacer(),
                                // Legend
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    _LegendDot(
                                      color: isDark
                                          ? AppColors.darkTeal
                                          : AppColors.lightTeal,
                                      label: 'Tokens',
                                    ),
                                    _LegendDot(
                                      color: isDark
                                          ? AppColors.darkViolet
                                          : AppColors.lightViolet,
                                      label: 'Trend',
                                    ),
                                    _LegendDot(
                                      color: AppColors.error,
                                      label: 'Fail',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            UsageChart(logs: logs),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Divider(
                        thickness: 1,
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),

                      // Recent Requests — filter + date-grouped compact
                      const SectionHeader(title: 'Recent Requests'),
                      if (logsAll.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              AppChip(
                                label: 'All',
                                selected: _filter == 'all',
                                onTap: () => setState(() {
                                  _filter = 'all';
                                  _displayLimit = 10;
                                }),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              for (final p in [
                                'gemini',
                                'groq',
                                'openrouter',
                                'cerebras',
                              ])
                                if (logsAll.any(
                                  (l) => l.providerId.toLowerCase() == p,
                                )) ...[
                                  AppChip(
                                    label: p[0].toUpperCase() + p.substring(1),
                                    selected: _filter == p,
                                    onTap: () => setState(() {
                                      _filter = p;
                                      _displayLimit = 10;
                                    }),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (logs.isEmpty && _filter != 'all')
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            'No requests for this provider.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final grouped = <String, List<UsageLog>>{};
                            final order = <String>[];
                            final displayLogs = logs.take(_displayLimit).toList();
                            for (final l in displayLogs) {
                              final d = l.timestamp;
                              String key;
                              if (d.year == now.year &&
                                  d.month == now.month &&
                                  d.day == now.day) {
                                key = 'Today';
                              } else if (d.year == now.year &&
                                  d.month == now.month &&
                                  d.day == now.day - 1) {
                                key = 'Yesterday';
                              } else {
                                key = DateFormat('MMM d, yyyy').format(d);
                              }
                              if (!grouped.containsKey(key)) {
                                grouped[key] = [];
                                order.add(key);
                              }
                              grouped[key]!.add(l);
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final dateKey in order) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.xs,
                                      top: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      dateKey.toUpperCase(),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            letterSpacing: 0.6,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.45),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ),
                                  for (final log in grouped[dateKey]!) ...[
                                    _buildLogCard(context, log),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                ],
                              ],
                            );
                          },
                        ),
                      if (logs.length > _displayLimit)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Center(
                            child: TextButton(
                              onPressed: () => setState(() => _displayLimit += 10),
                              child: const Text('View More'),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLogCard(BuildContext context, UsageLog log) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM d, HH:mm').format(log.timestamp);
    final providerTint = AppColors.tintForProvider(log.providerId, isDark);
    final providerSoft = AppColors.softForProvider(
      log.providerId,
      isDark,
    ).withValues(alpha: 0.35);

    return AppCard(
      accentColor: providerTint,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: providerSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              log.isSuccess ? Icons.check_rounded : Icons.close_rounded,
              color: log.isSuccess ? providerTint : AppColors.error,
              size: 14,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.providerModelText.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  timeStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${log.estimatedTokens} tokens • ${log.latencyMs}ms',
            style: AppTypography.mono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, UsageService service) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        backgroundColor: theme.colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Clear Usage History?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'This will permanently reset all recorded token usage, latency statistics, and request history.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: 'Clear History',
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      height: 40,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      Haptics.heavyImpact();
      service.clearLogs();
    }
  }
}

class _LegendDot extends ConsumerWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends ConsumerWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? (isDark ? AppColors.darkVioletSoft : AppColors.lightVioletSoft)
              .withValues(alpha: 0.45)
        : theme.colorScheme.surface;
    final fg = selected
        ? (isDark ? AppColors.darkViolet : AppColors.lightViolet)
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final border = selected
        ? (isDark ? AppColors.darkViolet : AppColors.lightViolet)
        : theme.colorScheme.outline;
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppSpacing.borderRadiusPill,
          border: Border.all(color: border, width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: fg,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
