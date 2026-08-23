import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';

/// Shimmer skeleton loader for placeholder loading states.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  static Widget textLine(BuildContext context, {double width = double.infinity, double height = 14}) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: AppSpacing.borderRadiusXs,
    );
  }

  static Widget outputCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonLoader(width: 120, height: 18, borderRadius: AppSpacing.borderRadiusXs),
            SkeletonLoader(width: 32, height: 32, borderRadius: AppSpacing.borderRadiusSm),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            SkeletonLoader(width: 60, height: 28, borderRadius: AppSpacing.borderRadiusPill),
            const SizedBox(width: AppSpacing.sm),
            SkeletonLoader(width: 80, height: 28, borderRadius: AppSpacing.borderRadiusPill),
            const SizedBox(width: AppSpacing.sm),
            SkeletonLoader(width: 65, height: 28, borderRadius: AppSpacing.borderRadiusPill),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SkeletonLoader.textLine(context),
        const SizedBox(height: AppSpacing.sm),
        SkeletonLoader.textLine(context),
        const SizedBox(height: AppSpacing.sm),
        SkeletonLoader.textLine(context, width: 220),
      ],
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = AppMotion.shouldReduceMotion(context) ? 0.5 : _animation.value;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: opacity),
            borderRadius: widget.borderRadius ?? AppSpacing.borderRadiusSm,
          ),
        );
      },
    );
  }
}
