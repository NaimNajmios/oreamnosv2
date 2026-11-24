import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';

/// Display state for a published post's insights.
enum FacebookInsightState {
  /// No refresh has run yet: show a small spinner while the refresher works.
  loading,

  /// At least one metric is on the record.
  ready,

  /// A refresh failed; `insightsError`/`engagementError` holds the short code.
  failed,

  /// A refresh succeeded but Facebook returned no metrics for this post.
  empty,
}

/// Derives the display state of a record's insights from the record fields.
FacebookInsightState stateFor(FacebookPostRecord record) {
  if (record.hasInsights) return FacebookInsightState.ready;
  if (record.insightsError != null || record.engagementError != null) {
    return FacebookInsightState.failed;
  }
  return record.lastRefreshAttemptAt == null
      ? FacebookInsightState.loading
      : FacebookInsightState.empty;
}

/// Shared metric rows for history, performance, and the Publish hub.
///
/// Views prefer the current unique-viewer metric and fall back to legacy
/// impressions, so a post never shows the same reach twice.
List<FacebookStat> facebookStatsFor(FacebookPostRecord record) {
  String compact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}m';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }

  final views = record.uniqueViewers ?? record.impressions;
  return [
    if (views != null)
      FacebookStat(
        icon: Icons.visibility_outlined,
        label: 'Views',
        value: compact(views),
      ),
    if (record.reactions != null)
      FacebookStat(
        icon: Icons.thumb_up_outlined,
        label: 'Reactions',
        value: compact(record.reactions!),
      ),
    if (record.comments != null)
      FacebookStat(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Comments',
        value: compact(record.comments!),
      ),
    if (record.shares != null)
      FacebookStat(
        icon: Icons.ios_share_rounded,
        label: 'Shares',
        value: compact(record.shares!),
      ),
    if (record.clicks != null)
      FacebookStat(
        icon: Icons.link_rounded,
        label: 'Clicks',
        value: compact(record.clicks!),
      ),
  ];
}

/// One labelled metric rendered as an icon + value.
class FacebookStat {
  const FacebookStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;

  /// Spoken label, e.g. "Reactions".
  final String label;

  /// Already formatted display value, e.g. "1.2k".
  final String value;
}

/// State line shown under a post row when there are no stats to display:
/// a spinner while loading, a short reason when the refresh failed, or the
/// empty message once a refresh succeeded. In the failed state the line is
/// tappable via [onTap].
class FacebookInsightStateLine extends StatelessWidget {
  const FacebookInsightStateLine({super.key, required this.record, this.onTap});

  final FacebookPostRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = stateFor(record);
    Widget line;
    switch (state) {
      case FacebookInsightState.loading:
        line = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case FacebookInsightState.ready:
        line = FacebookStatLine(stats: facebookStatsFor(record));
      case FacebookInsightState.failed:
        final reason =
            record.insightsError ?? record.engagementError ?? 'unavailable';
        line = InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusSm,
          child: Text(
            'Couldn’t load · $reason',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        );
      case FacebookInsightState.empty:
        line = Text(
          'Facebook has no data yet. Can lag up to 24h.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
    return line;
  }
}

/// Inline stats row that reads as icons instead of emoji glyphs.
///
/// The whole row exposes one semantics label ("Reactions 12, Comments 3")
/// so screen readers do not announce the individual decorative icons.
class FacebookStatLine extends StatelessWidget {
  const FacebookStatLine({super.key, required this.stats, this.onTap});

  final List<FacebookStat> stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final semantics = stats
        .map((stat) => '${stat.label} ${stat.value}')
        .join(', ');

    final row = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final stat in stats)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(stat.icon, size: 13, color: color),
              const SizedBox(width: 3),
              Text(
                stat.value,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
      ],
    );

    final content = onTap == null
        ? row
        : InkWell(
            onTap: onTap,
            borderRadius: AppSpacing.borderRadiusSm,
            child: row,
          );

    return Semantics(
      label: semantics,
      button: onTap != null,
      child: ExcludeSemantics(child: content),
    );
  }
}
