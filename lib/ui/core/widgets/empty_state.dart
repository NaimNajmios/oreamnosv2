import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'app_button.dart';

/// Illustrated serene empty state widget — now with breathing animation.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    // Start breathing if not reduced motion — single forward+reverse to allow pumpAndSettle in tests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.shouldReduceMotion(context)) return;
      _controller.forward().then((_) {
        if (mounted && !AppMotion.shouldReduceMotion(context)) _controller.reverse();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scale,
              builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.iconBackground ?? theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: widget.iconColor ?? theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                widget.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: widget.actionLabel!,
                height: 44,
                onPressed: widget.onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
