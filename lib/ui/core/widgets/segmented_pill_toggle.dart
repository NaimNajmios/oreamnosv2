import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Reusable Sciuro-style Segmented Pill Toggle component.
///
/// Features:
/// - 24dp corner radius container track
/// - 4dp inner padding
/// - 20dp individual pill radius
/// - Active pill lifts off with 3dp elevation and subtle ambient/spot color tint
/// - Inactive labels sit at 70-80% opacity
class SegmentedPillToggle<T> extends StatelessWidget {
  const SegmentedPillToggle({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    this.itemLabelBuilder,
  });

  final List<T> items;
  final T selectedItem;
  final ValueChanged<T> onChanged;
  final String Function(T item)? itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surfaceVariant = theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: surfaceVariant.withValues(alpha: isDark ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item == selectedItem;
          final label = itemLabelBuilder != null
              ? itemLabelBuilder!(item)
              : item.toString();

          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                Haptics.selection();
                onChanged(item);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppMotion.micro,
              curve: AppMotion.curveMicro,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? primary : primary)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.micro,
                curve: AppMotion.curveMicro,
                style: theme.textTheme.labelMedium!.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                      : theme.colorScheme.onSurface.withValues(
                          alpha: isDark ? 0.7 : 0.8,
                        ),
                ),
                child: Text(label),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
