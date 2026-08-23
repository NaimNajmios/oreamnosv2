import 'package:flutter/material.dart';

/// A card with sharp corners and subtle border — the foundation
/// of the Neo-Editorial design system.
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor = borderColor ??
        theme.colorScheme.onSurface.withAlpha(31);
    final effectiveBackground = backgroundColor ??
        theme.colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBackground,
          border: Border.all(color: effectiveBorderColor),
          // Neo-Editorial: sharp corners, zero border radius
        ),
        child: child,
      ),
    );
  }
}
