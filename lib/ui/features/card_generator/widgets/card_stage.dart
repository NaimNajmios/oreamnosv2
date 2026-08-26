import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';

class CardStage extends StatelessWidget {
  final GlobalKey boundaryKey;
  final double aspectRatio;
  final Widget child;

  const CardStage({
    super.key,
    required this.boundaryKey,
    required this.aspectRatio,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: AppSpacing.elevatedShadow(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: RepaintBoundary(key: boundaryKey, child: child),
          ),
        ),
      ),
    );
  }
}
