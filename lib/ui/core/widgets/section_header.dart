import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';

/// Clean uppercase section title header.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(
      left: AppSpacing.xs,
      bottom: AppSpacing.sm,
      top: AppSpacing.md,
    ),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, // Minimalist subtle section header
              fontWeight: FontWeight.w600,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

