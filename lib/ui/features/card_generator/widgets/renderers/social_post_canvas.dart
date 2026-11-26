import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/card_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../primitives/brand_footer.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';
import '../editable_canvas_text.dart';

class SocialPostCanvas extends StatelessWidget {
  const SocialPostCanvas({super.key, required this.data, required this.config});
  final SocialPost data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;

    return Container(
      decoration: BoxDecoration(
        gradient: config.backgroundImagePath != null
            ? null
            : GradientBuilder.vertical(colors),
      ),
      child: Stack(
        children: [
          if (config.showScrim)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: GradientBuilder.scrimFor(
                    config.scrimType,
                    config.overlayOpacity,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Social Header
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                data.name.isNotEmpty && data.name != 'N/A'
                                    ? data.name[0].toUpperCase()
                                    : 'ÃƒÂ¢Ã…Â¡Ã‚Â½',
                                style: config.font(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          data.name != 'N/A' &&
                                                  data.name.isNotEmpty
                                              ? data.name
                                              : (config.brandName?.isNotEmpty ==
                                                        true
                                                    ? config.brandName!
                                                    : 'Verified Account'),
                                          style: config.font(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            applyMultiplier: false,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (data.verified) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.verified_rounded,
                                          color: config.theme.accent,
                                          size: 14,
                                        ),
                                      ],
                                    ],
                                  ),
                                  EditableCanvasText(
                                    data.handle != 'N/A'
                                        ? data.handle
                                        : (config.brandHandle?.isNotEmpty ==
                                                  true
                                              ? config.brandHandle!
                                              : '@creator'),
                                    fieldKey: 'microStat',
                                    autoSize: false,
                                    style: config.font(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      applyMultiplier: false,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            if (data.mediaType != 'N/A')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  data.mediaType.toUpperCase(),
                                  style: CardFonts.jetBrainsMono(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Post Content ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â auto-scales, clipped if still too tall
                        ClipRect(
                          child: EditableCanvasText(
                            data.content,
                            fieldKey: 'headline',
                            autoSize: true,
                            minFontSize: 9,
                            style: config.font(
                              color: Colors.white,
                              fontSize: 18 * fontMultiplier,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              shadows: config.textShadowRadius > 0
                                  ? [
                                      Shadow(
                                        color: config.textShadowColor,
                                        blurRadius: config.textShadowRadius,
                                      ),
                                    ]
                                  : null,
                            ),
                            maxLines: 6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Metrics
                        if (data.metrics != 'N/A' &&
                            data.metrics.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: EditableCanvasText(
                              data.metrics,
                              fieldKey: 'subtext',
                              autoSize: false,
                              style: CardFonts.jetBrainsMono(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        BrandFooter(config: config, fallback: 'Social Feed'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
