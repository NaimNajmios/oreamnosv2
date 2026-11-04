import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Detail sheet for cached post insights. Every row is conditional: a metric
/// Facebook did not return is hidden, never rendered as zero.
class PostInsightsSheet extends ConsumerStatefulWidget {
  const PostInsightsSheet({super.key, required this.recordId});

  final String recordId;

  static Future<void> show(BuildContext context, String recordId) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => PostInsightsSheet(recordId: recordId),
    );
  }

  @override
  ConsumerState<PostInsightsSheet> createState() => _PostInsightsSheetState();
}

class _PostInsightsSheetState extends ConsumerState<PostInsightsSheet> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final error = await ref
        .read(facebookHistoryProvider.notifier)
        .refreshInsights(widget.recordId);
    if (!mounted) return;
    setState(() => _refreshing = false);
    Haptics.lightImpact();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = _record(ref.watch(facebookHistoryProvider), widget.recordId);
    if (record == null) return const SizedBox(height: 160);
    final rows = _rows(record);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          AppSpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Post insights',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_refreshing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'Refresh insights',
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: _refresh,
                  ),
              ],
            ),
            Text(
              record.snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (record.insightsFetchedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Updated ${_relativeTime(record.insightsFetchedAt!)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.base),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  "Facebook hasn't reported insights for this post yet.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        row.icon,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          row.label,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        _formatNumber(row.value),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            if (record.reactionsByType != null &&
                record.reactionsByType!.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                'Reactions by type',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final entry in record.reactionsByType!.entries)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${entry.key} ${entry.value}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static FacebookPostRecord? _record(
    List<FacebookPostRecord> records,
    String id,
  ) {
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  static List<_MetricRow> _rows(FacebookPostRecord record) {
    return [
      if (record.impressions != null)
        _MetricRow(
          icon: Icons.visibility_outlined,
          label: 'Reach',
          value: record.impressions!,
        ),
      if (record.totalImpressions != null)
        _MetricRow(
          icon: Icons.remove_red_eye_outlined,
          label: 'Impressions',
          value: record.totalImpressions!,
        ),
      if (record.reactions != null)
        _MetricRow(
          icon: Icons.thumb_up_alt_outlined,
          label: 'Reactions',
          value: record.reactions!,
        ),
      if (record.clicks != null)
        _MetricRow(
          icon: Icons.link_rounded,
          label: 'Clicks',
          value: record.clicks!,
        ),
      if (record.engagedUsers != null)
        _MetricRow(
          icon: Icons.groups_outlined,
          label: 'Engaged users',
          value: record.engagedUsers!,
        ),
      if (record.negativeFeedback != null)
        _MetricRow(
          icon: Icons.thumb_down_alt_outlined,
          label: 'Negative feedback',
          value: record.negativeFeedback!,
        ),
    ];
  }

  static String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}m';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }

  static String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}

class _MetricRow {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;
}
