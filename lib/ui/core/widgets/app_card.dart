import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Serene container card with surface fill, hairline border, and configurable radius.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.base),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.onTap,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.borderRadius ?? AppSpacing.borderRadiusLg;

    Widget card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.colorScheme.surface,
        borderRadius: radius,
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: 1)
            : null,
        boxShadow:
            widget.boxShadow ??
            AppSpacing.subtleShadow(theme.brightness == Brightness.dark),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (widget.onTap == null) return card;

    final reduceMotion = AppMotion.shouldReduceMotion(context);
    return AnimatedScale(
      scale: _pressed && !reduceMotion ? 0.98 : 1.0,
      duration: AppMotion.micro,
      curve: AppMotion.curveMicro,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Haptics.lightImpact();
            widget.onTap?.call();
          },
          onHighlightChanged: (value) {
            if (mounted) setState(() => _pressed = value);
          },
          borderRadius: radius,
          child: card,
        ),
      ),
    );
  }
}
