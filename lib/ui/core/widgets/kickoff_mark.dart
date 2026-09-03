import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_kickoff.dart';

/// Static kickoff motif mark derived from `icon/icon.svg`.
///
/// Monochrome base (themed `onSurface`/`surface`) with an optional single
/// accent orbit dot at [highlightedIndex]. Set [showDisc] to true for the
/// solid launcher-style disc, false for the transparent outline variant.
class KickoffMark extends StatelessWidget {
  const KickoffMark({
    super.key,
    this.size = 120.0,
    this.dotCount = AppKickoff.orbitCount,
    this.highlightedIndex = -1,
    this.dotColor,
    this.ringColor,
    this.accentColor,
    this.discColor,
    this.showDisc = false,
    this.showCenter = true,
    this.rotation = 0.0,
  });

  final double size;
  final int dotCount;
  final int highlightedIndex;
  final Color? dotColor;
  final Color? ringColor;
  final Color? accentColor;
  final Color? discColor;
  final bool showDisc;
  final bool showCenter;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Monochrome rule: dots/rings follow onSurface, disc follows surface
    // inverse so the mark reads in both light and dark Themes themes.
    final base = dotColor ?? colorScheme.onSurface;
    final ring = ringColor ?? base;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: KickoffMarkPainter(
          dotCount: dotCount,
          highlightedIndex: highlightedIndex,
          dotColor: base,
          ringColor: ring,
          accentColor: accentColor ?? colorScheme.primary,
          discColor: discColor,
          showDisc: showDisc,
          showCenter: showCenter,
          rotation: rotation,
        ),
      ),
    );
  }
}

/// Painter backing [KickoffMark]. All geometry derives from [AppKickoff].
class KickoffMarkPainter extends CustomPainter {
  KickoffMarkPainter({
    this.dotCount = AppKickoff.orbitCount,
    this.highlightedIndex = -1,
    required this.dotColor,
    required this.ringColor,
    required this.accentColor,
    this.discColor,
    this.showDisc = false,
    this.showCenter = true,
    this.rotation = 0.0,
  });

  final int dotCount;
  final int highlightedIndex;
  final Color dotColor;
  final Color ringColor;
  final Color accentColor;
  final Color? discColor;
  final bool showDisc;
  final bool showCenter;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512.0;
    canvas.save();
    canvas.scale(scale, scale);
    const center = Offset(256.0, 256.0);

    if (showDisc && discColor != null) {
      canvas.drawCircle(
        center,
        512 * AppKickoff.discRadiusFactor,
        Paint()..color = discColor!,
      );
    }

    if (showCenter) {
      canvas.drawCircle(
        center,
        512 * AppKickoff.ringRadiusFactor,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 512 * AppKickoff.ringStrokeFactor,
      );
      canvas.drawCircle(
        center,
        512 * AppKickoff.coreRadiusFactor,
        Paint()..color = ringColor,
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final orbitR = 512 * AppKickoff.orbitRadiusFactor;
    final dotR = 512 * AppKickoff.dotRadiusFactor;
    for (var i = 0; i < dotCount; i++) {
      final angle = (i * 2 * math.pi) / dotCount - math.pi / 2;
      final offset = Offset(
        orbitR * math.cos(angle),
        orbitR * math.sin(angle),
      );
      canvas.drawCircle(
        offset,
        dotR,
        Paint()..color = i == highlightedIndex ? accentColor : dotColor,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KickoffMarkPainter oldDelegate) {
    return oldDelegate.dotCount != dotCount ||
        oldDelegate.highlightedIndex != highlightedIndex ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.discColor != discColor ||
        oldDelegate.showDisc != showDisc ||
        oldDelegate.showCenter != showCenter ||
        oldDelegate.rotation != rotation;
  }
}

/// Small dotted section separator in the kickoff language.
class KickoffDotsDivider extends StatelessWidget {
  const KickoffDotsDivider({super.key, this.count = 5, this.opacity = 0.35});

  final int count;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: opacity);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Container(
          width: 4,
          height: 4,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Compact app-bar leading mark (transparent, no disc).
class KickoffAppBarMark extends StatelessWidget {
  const KickoffAppBarMark({super.key, this.size = 28.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return KickoffMark(size: size);
  }
}
