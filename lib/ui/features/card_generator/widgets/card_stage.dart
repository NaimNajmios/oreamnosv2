import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
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
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 24, spreadRadius: 4),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: reduceMotion
                ? RepaintBoundary(key: boundaryKey, child: child)
                : AnimatedSwitcher(
                    duration: AppMotion.cardMove,
                    switchInCurve: AppMotion.curveCardMove,
                    child: RepaintBoundary(
                      key: ValueKey(
                        '${boundaryKey.hashCode}-$aspectRatio',
                      ),
                      child: child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
