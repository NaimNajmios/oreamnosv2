import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../data/services/usage_service.dart';
import '../../../../domain/models/usage_log.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import 'widgets/usage_chart.dart';

/// Serene Editorial Usage & Analytics screen.
class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageService = context.watch<UsageService>();
    final logs = usageService.logs;

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
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear History',
              onPressed: () => _confirmClear(context, usageService),
            ),
        ],
      ),
      body: logs.isEmpty
          ? const EmptyState(
              icon: Icons.analytics_outlined,
              title: 'No Usage Data Yet',
              description: 'Generated posts and API latency statistics will appear here.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.base,
                  ),
                  children: [
                    // 3 Metric StatCards
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Tokens',
                            value: NumberFormat.compact().format(totalTokens),
                            subtitle: '$totalTokens est.',
                            icon: Icons.data_usage_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatCard(
                            title: 'Success',
                            value: '${successRate.toStringAsFixed(0)}%',
                            subtitle: '$successCount / ${logs.length}',
                            icon: Icons.check_circle_outline_rounded,
                            valueColor: successRate >= 90
                                ? AppColors.success
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatCard(
                            title: 'Avg Latency',
                            value: '${avgLatency}ms',
                            subtitle: 'Per prompt',
                            icon: Icons.speed_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Usage Chart
                    const SectionHeader(title: 'Token Usage History'),
                    UsageChart(logs: logs),
                    const SizedBox(height: AppSpacing.lg),

                    // Recent Requests
                    const SectionHeader(title: 'Recent Requests'),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _buildLogCard(context, logs[index]),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLogCard(BuildContext context, UsageLog log) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('MMM d, HH:mm').format(log.timestamp);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: log.isSuccess
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              log.isSuccess ? Icons.check_rounded : Icons.close_rounded,
              color: log.isSuccess ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.providerId.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log.estimatedTokens} tokens',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${log.latencyMs}ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
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
