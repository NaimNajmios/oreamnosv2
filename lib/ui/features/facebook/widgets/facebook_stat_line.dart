import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';

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
