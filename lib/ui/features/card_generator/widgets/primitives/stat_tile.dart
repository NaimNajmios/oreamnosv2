import 'package:flutter/material.dart';

import '../../../../../config/theme/card_type.dart';
import 'glass_tile.dart';

/// A compact bento-style stat tile with tabular numerals.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.accent,
    this.width = 92,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? accent;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? CardType.display.color ?? Colors.white;
    return SizedBox(
      width: width,
      child: GlassTile(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: CardType.display.copyWith(fontSize: 32, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label.toUpperCase(),
              style: CardType.label.copyWith(
                fontSize: 10,
                letterSpacing: 1.2,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (caption != null && caption!.isNotEmpty)
              Text(
                caption!,
                style: CardType.body.copyWith(
                  fontSize: 10,
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
