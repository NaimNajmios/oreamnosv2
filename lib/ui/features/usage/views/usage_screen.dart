import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/routes/app_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_motion.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../core/widgets/staggered_entrance.dart';
import '../../../../data/services/usage_export_formatter.dart';
import '../../../../data/services/usage_service.dart';
import '../../../../data/services/daily_usage_service.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../data/models/ai_provider.dart';
import '../../../../domain/models/usage_log.dart';
import '../../../../core/di/injection.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/segmented_pill_toggle.dart';
import '../view_models/usage_analytics.dart';
import '../view_models/usage_filter_view_model.dart';
import 'widgets/provider_charts.dart';
import 'widgets/usage_chart.dart';
import 'widgets/usage_tables.dart';

/// Serene Editorial Usage & Analytics screen — grouped, filtered, responsive.
class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  int _displayLimit = 10;
  bool _showTokenTable = false;
  bool _showSuccessTable = false;
  bool _showLatencyTable = false;
  String? _bannerDismissedKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logsAll = ref.watch(usageNotifierProvider);
    final usageNotifier = ref.watch(usageNotifierProvider.notifier);
    final filter = ref.watch(usageFilterProvider);
    final filterNotifier = ref.read(usageFilterProvider.notifier);
    final analytics = UsageAnalytics.from(
      logsAll,
      rangeDays: filter.rangeDays,
      providerFilter: filter.providerFilter,
    );
    final logs = analytics.logs;
    final rangeLabel = analytics.rangeLabel;
    final truncated =
        filter.rangeDays != 0 && logsAll.length >= usageNotifier.maxLogs;

    // Daily RPD budget (device-local estimate; refreshes with usage logs).
    DailyUsageService? dailyUsage;
    try {
      if (getIt.isRegistered<DailyUsageService>()) {
        dailyUsage = getIt<DailyUsageService>();
      }
    } catch (_) {
      dailyUsage = null;
    }

    // Budget warning banner: exhausted first, then warning. Dismissible per
    // (model, Pacific day) — re-appears tomorrow or when usage climbs again.
    DailyQuota? bannerQuota;
    final geminiQuota = dailyUsage?.todayGeminiQuota() ?? const [];
    if (_bannerDismissedKey != _todayKey() && geminiQuota.isNotEmpty) {
      bannerQuota = geminiQuota.firstWhere(
        (q) => q.isExhausted,
        orElse: () => geminiQuota.firstWhere(
          (q) => q.isWarning,
          orElse: () =>
              const DailyQuota(modelId: '', requestsToday: 0, budget: 0),
        ),
      );
      if (bannerQuota.modelId.isEmpty) bannerQuota = null;
    }
    final historyOptions = _historySizeOptions(usageNotifier.maxLogs);

    final totalTokens = analytics.totalTokens;
    final successCount = analytics.successCount;
    final successRate = analytics.successRate;
    final avgLatency = analytics.avgLatency;
    // At very large text the inline title + legend cannot fit; stack them so
    // 100% keeps the original single-row arrangement.
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final chartIcon = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkVioletSoft : AppColors.lightVioletSoft)
            .withValues(alpha: 0.35),
        borderRadius: AppSpacing.borderRadiusXs,
      ),
      child: Icon(
        Icons.show_chart_rounded,
        size: 14,
        color: isDark ? AppColors.darkViolet : AppColors.lightViolet,
      ),
    );
    final chartTitle = Text(
      'Token Usage History',
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
    final chartLegend = Wrap(
      spacing: 10,
      children: [
        _LegendDot(
          color: isDark ? AppColors.darkTeal : AppColors.lightTeal,
          label: 'Tokens',
        ),
        _LegendDot(
          color: isDark ? AppColors.darkViolet : AppColors.lightViolet,
          label: 'Trend',
        ),
        _LegendDot(color: AppColors.error, label: 'Fail'),
      ],
    );

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
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export History',
            onPressed: logsAll.isEmpty
                ? null
                : () => _exportDialog(context, analytics),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Session History',
            onPressed: () => context.push(RoutePaths.sessionHistory),
          ),
          if (logsAll.isNotEmpty ||
              (dailyUsage?.hasGeminiActivityToday() ?? false))
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear History',
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: logsAll.isEmpty
          ? EmptyState(
              icon: Icons.analytics_outlined,
              title: 'No Usage Data Yet',
              description: 'Generated posts and API latency statistics will appear here.',
              illustrationStyle: EmptyIllustrationStyle.kickoff,
              kickoffAccentIndex: 4,
              actionLabel: 'Generate first post',
              onAction: () => context.go(RoutePaths.generate),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(usageNotifierProvider.notifier).reload();
                    Haptics.mediumImpact();
                  },
                  color: theme.colorScheme.primary,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.base,
                    ),
                    children: [
                      // Budget warning banner when the Gemini free tier is
                      // nearing (or at) its daily window.
                      if (bannerQuota != null) ...[
                        _UsageBudgetBanner(
                          quota: bannerQuota,
                          onDismiss: () {
                            setState(() => _bannerDismissedKey = _todayKey());
                            Haptics.lightImpact();
                          },
                        ),
                        const SizedBox(height: AppSpacing.base),
                      ],
                      // 3 Metric StatCards — responsive, no truncation
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 380;
                          final reduceMotion = AppMotion.shouldReduceMotion(
                            context,
                          );
                          Widget countUp(
                            int index,
                            double target,
                            String Function(double) format,
                            StatCard Function(String) build,
                          ) {
                            if (reduceMotion) {
                              return StaggeredEntranceItem(
                                index: index,
                                child: build(format(target)),
                              );
                            }
                            return StaggeredEntranceItem(
                              index: index,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: target),
                                duration: AppMotion.count,
                                curve: AppMotion.curveCount,
                                builder: (context, value, _) =>
                                    build(format(value)),
                              ),
                            );
                          }

                          final tokensCard = countUp(
                            0,
                            totalTokens.toDouble(),
                            (v) => NumberFormat.compact().format(v.round()),
                            (value) => StatCard(
                              title: 'Tokens',
                              value: value,
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
                            ),
                          );
                          final successCard = countUp(
                            1,
                            successRate,
                            (v) => '${v.toStringAsFixed(0)}%',
                            (value) => StatCard(
                              title: 'Success',
                              value: value,
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
                            ),
                          );
                          final latencyCard = countUp(
                            2,
                            avgLatency.toDouble(),
                            (v) => '${v.round()}ms',
                            (value) => StatCard(
                              title: 'Avg Latency',
                              value: value,
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
                            ),
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

                      // BY MODEL — per-model requests/tokens/latency summary
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: ModelBreakdownTable(logs: logs),
                      ),
                      const SizedBox(height: AppSpacing.base),

                      // DAILY QUOTA — Gemini estimated free-tier budget
                      if (dailyUsage != null &&
                          dailyUsage.hasGeminiActivityToday()) ...[
                        _buildDailyQuotaCard(context, dailyUsage),
                        const SizedBox(height: AppSpacing.base),
                      ],

                      // Usage Chart — grouped card with legend
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (largeText)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      chartIcon,
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(child: chartTitle),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  chartLegend,
                                ],
                              )
                            else
                              Row(
                                children: [
                                  chartIcon,
                                  const SizedBox(width: AppSpacing.sm),
                                  chartTitle,
                                  const Spacer(),
                                  chartLegend,
                                ],
                              ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                for (final days in [0, 7, 30, 90]) ...[
                                  AppChip(
                                    label: days == 0 ? 'All' : '${days}d',
                                    selected: filter.rangeDays == days,
                                    onTap: () =>
                                        filterNotifier.setRangeDays(days),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                const Spacer(),
                                _TableToggle(
                                  showingTable: _showTokenTable,
                                  onPressed: () => setState(
                                    () => _showTokenTable = !_showTokenTable,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 74,
                                    child: Text(
                                      'History',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ),
                                  SegmentedPillToggle<int>(
                                    items: historyOptions,
                                    selectedItem: usageNotifier.maxLogs,
                                    itemLabelBuilder: (v) => v.toString(),
                                    onChanged: _setHistorySize,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            if (truncated) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Showing the most recent '
                                '${usageNotifier.maxLogs} requests',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            if (!analytics.hasData)
                              _NoRangeData(
                                rangeLabel: rangeLabel,
                                onShowAll: filterNotifier.resetToAllTime,
                              )
                            else if (_showTokenTable)
                              UsageTable(logs: logs)
                            else
                              StaggeredEntranceItem(
                                index: 3,
                                child: Semantics(
                                  container: true,
                                  label: _tokenChartLabel(analytics),
                                  child: ExcludeSemantics(
                                    child: AnimatedSwitcher(
                                      duration: AppMotion.transitionSpec,
                                      switchInCurve: AppMotion.curveTransition,
                                      child: KeyedSubtree(
                                        key: ValueKey(
                                          '${filter.rangeDays}_'
                                          '${filter.providerFilter}_'
                                          '${logs.length}',
                                        ),
                                        child: UsageChart(logs: logs),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),

                      // Success Rate — donut + per-provider breakdown
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'SUCCESS RATE',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                                _TableToggle(
                                  showingTable: _showSuccessTable,
                                  onPressed: () => setState(
                                    () =>
                                        _showSuccessTable = !_showSuccessTable,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (!analytics.hasData)
                              _NoRangeData(
                                rangeLabel: rangeLabel,
                                onShowAll: filterNotifier.resetToAllTime,
                              )
                            else if (_showSuccessTable)
                              SuccessRateTable(logs: logs)
                            else
                              Semantics(
                                container: true,
                                label: _successChartLabel(analytics),
                                child: ExcludeSemantics(
                                  child: SuccessRateDonut(logs: logs),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),

                      // Response Time — per-provider averages + badges
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'RESPONSE TIME',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                                _TableToggle(
                                  showingTable: _showLatencyTable,
                                  onPressed: () => setState(
                                    () =>
                                        _showLatencyTable = !_showLatencyTable,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (!analytics.hasData)
                              _NoRangeData(
                                rangeLabel: rangeLabel,
                                onShowAll: filterNotifier.resetToAllTime,
                              )
                            else if (_showLatencyTable)
                              ResponseTimeTable(logs: logs)
                            else
                              Semantics(
                                container: true,
                                label: _latencyChartLabel(analytics),
                                child: ExcludeSemantics(
                                  child: ResponseTimeBars(logs: logs),
                                ),
                              ),
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
                                selected: filter.providerFilter == 'all',
                                onTap: () {
                                  filterNotifier.setProviderFilter('all');
                                  setState(() => _displayLimit = 10);
                                },
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              for (final p in [
                                for (final provider in AiProvider.values)
                                  provider.name.toLowerCase(),
                              ])
                                if (logsAll.any(
                                  (l) => l.providerId.toLowerCase() == p,
                                )) ...[
                                  AppChip(
                                    label: p[0].toUpperCase() + p.substring(1),
                                    selected: filter.providerFilter == p,
                                    onTap: () {
                                      filterNotifier.setProviderFilter(p);
                                      setState(() => _displayLimit = 10);
                                    },
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (logs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            filter.providerFilter == 'all'
                                ? 'No requests in this range.'
                                : 'No requests for this provider in this range.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final yesterday = DateTime(
                              now.year,
                              now.month,
                              now.day - 1,
                            );
                            final grouped = <String, List<UsageLog>>{};
                            final order = <String>[];
                            final displayLogs = logs
                                .take(_displayLimit)
                                .toList();
                            for (final l in displayLogs) {
                              final d = l.timestamp;
                              String key;
                              if (d.year == today.year &&
                                  d.month == today.month &&
                                  d.day == today.day) {
                                key = 'Today';
                              } else if (d.year == yesterday.year &&
                                  d.month == yesterday.month &&
                                  d.day == yesterday.day) {
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
                              onPressed: () =>
                                  setState(() => _displayLimit += 10),
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

  Widget _buildDailyQuotaCard(BuildContext context, DailyUsageService daily) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quotas = daily.todayGeminiQuota();
    final reset = daily.timeUntilPacificReset();
    final resetLabel = reset.inHours > 0
        ? '${reset.inHours}h ${reset.inMinutes % 60}m'
        : '${reset.inMinutes}m';

    return AppCard(
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
                              ? AppColors.darkAmberSoft
                              : AppColors.lightAmberSoft)
                          .withValues(alpha: 0.35),
                  borderRadius: AppSpacing.borderRadiusXs,
                ),
                child: Icon(
                  Icons.speed_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkAmber : AppColors.lightAmber,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'DAILY QUOTA — GEMINI (EST.)',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final q in quotas) ...[
            _DailyQuotaRow(quota: q),
            if (q != quotas.last) const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Resets in $resetLabel (midnight PT). Device-local estimate — '
            'your real Google-project quota may include other keys.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  String _tokenChartLabel(UsageAnalytics analytics) {
    final total = NumberFormat.compact().format(analytics.totalTokens);
    return 'Token usage, ${analytics.logs.length} '
        '${analytics.logs.length == 1 ? 'request' : 'requests'}, '
        'total $total tokens, ${analytics.rangeLabel}.';
  }

  String _successChartLabel(UsageAnalytics analytics) {
    final parts = <String>[];
    for (final provider in _providers(analytics.logs)) {
      final mine = analytics.logs
          .where((log) => log.providerId.toLowerCase() == provider)
          .toList(growable: false);
      final rate = mine.isEmpty
          ? 0
          : (mine.where((log) => log.isSuccess).length / mine.length * 100)
                .round();
      parts.add('${provider[0].toUpperCase()}${provider.substring(1)} $rate%');
    }
    return 'Success rate ${analytics.successRate.round()}%, '
        '${analytics.successCount} of ${analytics.logs.length} '
        'requests${parts.isEmpty ? '' : ', ${parts.join(', ')}'}.';
  }

  String _latencyChartLabel(UsageAnalytics analytics) {
    final parts = <String>[];
    for (final provider in _providers(analytics.logs)) {
      final mine = analytics.logs
          .where((log) => log.providerId.toLowerCase() == provider)
          .toList(growable: false);
      if (mine.isEmpty) continue;
      final avg =
          mine.fold<int>(0, (sum, log) => sum + log.latencyMs) ~/ mine.length;
      parts.add(
        '${provider[0].toUpperCase()}${provider.substring(1)} ${avg}ms',
      );
    }
    return 'Average response time: ${parts.join(', ')}.';
  }

  static List<String> _providers(List<UsageLog> logs) {
    final providers = <String>[];
    for (final log in logs) {
      final id = log.providerId.toLowerCase();
      if (!providers.contains(id)) providers.add(id);
    }
    return providers;
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
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
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

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
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
                  'This permanently clears request history, token and latency statistics, and today\'s device-local daily quota counters.',
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
      await ref.read(usageNotifierProvider.notifier).clearLogs();
      try {
        if (getIt.isRegistered<DailyUsageService>()) {
          await getIt<DailyUsageService>().clearAll();
        }
      } catch (_) {}
    }
  }

  static const List<int> _baseHistorySizes = [50, 100, 200, 500, 1000, 2000];

  List<int> _historySizeOptions(int current) {
    if (_baseHistorySizes.contains(current)) return _baseHistorySizes;
    return [..._baseHistorySizes, current]..sort();
  }

  static String _todayKey() => DailyUsageService.pacificDayKey(DateTime.now());

  /// Persist the adjustable history ring size and re-read the logs.
  Future<void> _setHistorySize(int size) async {
    if (size < UsageService.minMaxLogs || size > UsageService.maxMaxLogs) {
      return;
    }
    await getIt<PreferencesService>().setUsageLogMaxSize(size);
    Haptics.lightImpact();
    await ref.read(usageNotifierProvider.notifier).reload();
  }

  Future<void> _exportDialog(
    BuildContext context,
    UsageAnalytics analytics,
  ) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Usage'),
        content: const Text(
          'Export the filtered usage history as CSV or JSON.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('csv'),
            child: const Text('CSV'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('json'),
            child: const Text('JSON'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    final logs = analytics.logs;
    if (logs.isEmpty) return;
    final content = choice == 'json'
        ? UsageExportFormatter.json(
            logs,
            rangeLabel: analytics.rangeLabel,
            providerFilter: analytics.providerFilter,
          )
        : UsageExportFormatter.csv(logs);
    try {
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp =
          '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final file = File('${dir.path}/oreamnos_usage_$stamp.$choice');
      await file.writeAsString(content, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: choice == 'json' ? 'application/json' : 'text/csv',
            ),
          ],
          subject: 'Oreamnos usage history',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't export the history")),
        );
      }
    }
  }
}

/// Dismissible banner shown on the Usage tab when the Gemini free-tier
/// daily budget is at/over the warning threshold.
class _UsageBudgetBanner extends StatelessWidget {
  const _UsageBudgetBanner({required this.quota, required this.onDismiss});

  final DailyQuota quota;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExhausted = quota.isExhausted;
    final color = isExhausted ? AppColors.error : AppColors.warning;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Icon(Icons.gpp_maybe_rounded, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExhausted
                      ? 'Gemini free-tier budget is full'
                      : 'Gemini free-tier budget nearing limit',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${quota.requestsToday} / ${quota.budget} requests today — '
                  'resets at midnight PT (device-local estimate).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// Shared empty state shown inside a chart card when the active range or
/// provider filter yields no requests.
class _NoRangeData extends StatelessWidget {
  const _NoRangeData({required this.rangeLabel, required this.onShowAll});

  final String rangeLabel;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Column(
        children: [
          Icon(
            Icons.query_stats_rounded,
            size: 28,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No requests in $rangeLabel',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(onPressed: onShowAll, child: const Text('Show all time')),
        ],
      ),
    );
  }
}

/// Chart/table switch shared by the three Usage cards. Compact so the card
/// headers keep their original height.
class _TableToggle extends StatelessWidget {
  const _TableToggle({required this.showingTable, required this.onPressed});

  final bool showingTable;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: showingTable ? 'Show chart' : 'View as table',
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            showingTable
                ? Icons.show_chart_rounded
                : Icons.table_chart_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// One model row in the DAILY QUOTA card: label + count/budget + progress.
class _DailyQuotaRow extends StatelessWidget {
  const _DailyQuotaRow({required this.quota});

  final DailyQuota quota;

  Color _barColor(BuildContext context) {
    if (quota.isExhausted) return AppColors.error;
    if (quota.isWarning) return Colors.orange.shade600;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _barColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                quota.modelId,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${quota.requestsToday} / ${quota.budget}',
              style: AppTypography.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: quota.isExhausted
                    ? AppColors.error
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: quota.fraction,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
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
