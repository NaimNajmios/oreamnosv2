import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../data/services/usage_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';

class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allLogs = ref.watch(usageNotifierProvider);
    final logs = _filter == 'all'
        ? allLogs
        : allLogs.where((l) => l.providerId.toLowerCase() == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (allLogs.isNotEmpty)
              Text(
                '${logs.length} of ${allLogs.length} sessions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
      body: allLogs.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: 'No Sessions Yet',
              description: 'Your generation sessions will appear here.',
              illustrationStyle: EmptyIllustrationStyle.kickoff,
              kickoffAccentIndex: 9,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Column(
                  children: [
                    if (allLogs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                          vertical: AppSpacing.sm,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: _filter == 'all',
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _filter = 'all'),
                              ),
                              const SizedBox(width: 8),
                              for (final p in [
                                'gemini',
                                'groq',
                                'openrouter',
                                'cerebras',
                              ])
                                if (allLogs.any(
                                  (l) => l.providerId.toLowerCase() == p,
                                )) ...[
                                  FilterChip(
                                    label: Text(
                                      p[0].toUpperCase() + p.substring(1),
                                    ),
                                    selected: _filter == p,
                                    showCheckmark: false,
                                    onSelected: (_) =>
                                        setState(() => _filter = p),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: logs.isEmpty
                          ? Center(
                              child: Text(
                                'No sessions for this provider.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(
                                AppSpacing.screenHorizontal,
                              ),
                              itemCount: logs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                final isSuccess = log.isSuccess;
                                final providerColor = AppColors.tintForProvider(
                                  log.providerId,
                                  isDark,
                                );
                                return AppCard(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: isSuccess
                                              ? AppColors.success
                                              : AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log.providerModelText,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${log.formattedTime} • ${log.latencyMs}ms',
                                              style: AppTypography.mono(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSuccess
                                              ? providerColor.withValues(
                                                  alpha: 0.12,
                                                )
                                              : AppColors.error.withValues(
                                                  alpha: 0.12,
                                                ),
                                          borderRadius:
                                              AppSpacing.borderRadiusXs,
                                        ),
                                        child: Text(
                                          isSuccess
                                              ? '${log.estimatedTokens} tokens'
                                              : 'Failed',
                                          style: AppTypography.mono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isSuccess
                                                ? providerColor
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
