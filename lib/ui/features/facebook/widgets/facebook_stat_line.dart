import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';

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
