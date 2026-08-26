import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Reusable Segmented Pill Toggle component (Aperture Design)
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: theme.colorScheme.outline, width: 1.0),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.micro,
                curve: AppMotion.curveMicro,
                style: theme.textTheme.labelLarge!.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.surface
                      : theme.colorScheme.onSurface,
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
