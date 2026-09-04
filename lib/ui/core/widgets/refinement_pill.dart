import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';

/// Interactive AI refinement suggestion pill widget.
class RefinementPill extends StatelessWidget {
  const RefinementPill({
    super.key,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isSelected = false,
    this.isActive = false,
    this.isDisabled = false,
    this.onTap,
    this.onLongPress,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isSelected;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  bool get _selected => isSelected || isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canInteract = !isLoading && !isDisabled;

    final backgroundColor = _selected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
        : theme.colorScheme.surface;

    final borderColor = _selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    final textColor = _selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    final iconColor = theme.colorScheme.primary;

    return Semantics(
      button: true,
      selected: _selected,
      enabled: canInteract,
      label: label,
      onTapHint: _selected ? 'Deselect refinement' : 'Select refinement',
      onLongPressHint: onLongPress != null ? 'Edit custom pill' : null,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canInteract
                ? () {
                    Haptics.lightImpact();
                    onTap?.call();
                  }
                : null,
            onLongPress: canInteract && onLongPress != null
                ? () {
                    Haptics.mediumImpact();
                    onLongPress?.call();
                  }
                : null,
            borderRadius: AppSpacing.borderRadiusPill,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: AppSpacing.borderRadiusPill,
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: KickoffLoadingIndicator(size: 12),
                    ),
                    const SizedBox(width: 6),
                  ] else if (_selected) ...[
                    Icon(Icons.check_rounded, size: 14, color: iconColor),
                    const SizedBox(width: 6),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 14, color: iconColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: _selected ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
