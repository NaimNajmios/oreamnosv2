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
    this.onTap,
    this.onLongPress,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                Haptics.lightImpact();
                onTap?.call();
              },
        onLongPress: onLongPress == null
            ? null
            : () {
                Haptics.mediumImpact();
                onLongPress?.call();
              },
        borderRadius: AppSpacing.borderRadiusPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusPill,
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 12,
                  height: 12,
                  child: KickoffLoadingIndicator(
                    size: 12,
                  ),
                ),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
