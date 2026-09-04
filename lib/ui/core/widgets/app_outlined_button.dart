import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';

/// Secondary outlined action button with hairline border and press animation.
class AppOutlinedButton extends StatefulWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.borderColor,
    this.foregroundColor,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final Color? borderColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  @override
  State<AppOutlinedButton> createState() => _AppOutlinedButtonState();
}

class _AppOutlinedButtonState extends State<AppOutlinedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.fast);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.curveFast));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      Haptics.lightImpact();
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null && !widget.isLoading;

    final outlineColor =
        widget.borderColor ??
        (enabled
            ? theme.colorScheme.outline
            : theme.colorScheme.outline.withValues(alpha: 0.4));
    final fgColor =
        widget.foregroundColor ??
        (enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.4));

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: AppMotion.shouldReduceMotion(context)
              ? 1.0
              : _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: AppSpacing.borderRadiusPill,
            border: Border.all(color: outlineColor, width: 1),
          ),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: KickoffLoadingIndicator(size: 20),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: fgColor),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: fgColor,
                            ),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
