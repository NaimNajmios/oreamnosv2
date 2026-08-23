import 'package:flutter/material.dart';
import '../utils/haptics.dart';

class RefinementPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isLoading;

  const RefinementPill({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () {
          Haptics.selectionClick();
          onTap();
        },
        onLongPress: isLoading ? null : () {
          if (onLongPress != null) {
            Haptics.selectionClick(); // Provide feedback for long press
            onLongPress!();
          }
        },
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary),
            color: theme.colorScheme.primary.withAlpha(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

