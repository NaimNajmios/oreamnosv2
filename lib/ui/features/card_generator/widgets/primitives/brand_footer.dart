import 'package:flutter/material.dart';

import '../../../../../config/theme/card_fonts.dart';
import '../../../../../domain/models/card_config.dart';
import 'crest_badge.dart';

/// One consistent brand lockup for every card template.
///
/// Honours `CardConfig.showBrandFooter`; uses the user's brand name, then
/// handle, then [fallback]. An optional [crestPath] renders a user-supplied
/// crest (with monogram fallback) ahead of the label.
class BrandFooter extends StatelessWidget {
  const BrandFooter({
    super.key,
    required this.config,
    this.fallback = 'Oreamnos',
    this.trailing,
    this.crestPath,
    this.showCrest = false,
    this.color,
    this.fontSize = 10,
  });

  final CardConfig config;
  final String fallback;
  final String? trailing;
  final String? crestPath;
  final bool showCrest;
  final Color? color;
  final double fontSize;

  String get label {
    final name = config.brandName;
    if (name != null && name.isNotEmpty) return name;
    final handle = config.brandHandle;
    if (handle != null && handle.isNotEmpty) return handle;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (!config.showBrandFooter) return const SizedBox.shrink();

    final effectiveColor = color ?? config.theme.accent;
    final children = <Widget>[
      if (showCrest)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CrestBadge(
            imagePath: crestPath,
            label: label,
            size: fontSize * 1.8,
            color: effectiveColor,
          ),
        ),
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: CardFonts.jetBrainsMono(
            color: effectiveColor.withValues(alpha: 0.85),
            fontSize: fontSize,
          ),
        ),
      ),
      if (trailing != null && trailing!.isNotEmpty) ...[
        const Spacer(),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            trailing!,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: CardFonts.jetBrainsMono(
              color: effectiveColor.withValues(alpha: 0.65),
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    ];

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
