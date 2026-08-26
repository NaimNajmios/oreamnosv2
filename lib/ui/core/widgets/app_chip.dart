import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Serene pill chip with animated selected states and hairline borders.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
    this.selectedColor,
    this.selectedTextColor,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? count;
  final Color? selectedColor;
  final Color? selectedTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = selected
        ? (selectedColor ?? theme.colorScheme.primaryContainer)
        : theme.colorScheme.surface;

    final border = selected
        ? (selectedColor ?? theme.colorScheme.primary)
        : theme.colorScheme.outline;

    final textCol = selected
        ? (selectedTextColor ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                Haptics.selectionClick();
                onTap?.call();
              },
        borderRadius: AppSpacing.borderRadiusXl,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppSpacing.borderRadiusXl,
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textCol),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textCol,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: textCol.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Text(
                    count.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
