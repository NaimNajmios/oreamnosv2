import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/card_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../primitives/broadcast_background.dart';
import '../primitives/brand_footer.dart';
import '../../../../../domain/models/card_data.dart';

import '../editable_canvas_text.dart';

class BreakingNewsCanvas extends StatelessWidget {
  const BreakingNewsCanvas({
    super.key,
    required this.data,
    required this.config,
  });
  final BreakingNews data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final fontMultiplier = config.fontSizeMultiplier;

    return BroadcastBackground(
      config: config,
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Red Breaking Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: config.theme.alert,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: config.theme.alert.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data.label.isNotEmpty
                        ? data.label.toUpperCase()
                        : 'BREAKING NEWS',
                    style: CardFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            EditableCanvasText(
              data.headline,
              fieldKey: 'headline',
              style: config.font(
                color: Colors.white,
                fontSize: 26 * fontMultiplier,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
                shadows: config.textShadowRadius > 0
                    ? [
                        Shadow(
                          color: config.textShadowColor,
                          blurRadius: config.textShadowRadius,
                        ),
                      ]
                    : null,
              ),
              maxLines: 4,
              minFontSize: 12,
            ),
            if (data.subtext.isNotEmpty && data.subtext != 'N/A') ...[
              const SizedBox(height: 12),
              EditableCanvasText(
                data.subtext,
                fieldKey: 'subtext',
                style: config.font(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.3,
                ),
                maxLines: 3,
                minFontSize: 9,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                BrandFooter(config: config, fallback: 'News Alert'),
                const Spacer(),
                if (data.relatedTeams != 'N/A')
                  Text(
                    data.relatedTeams,
                    style: CardFonts.jetBrainsMono(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
