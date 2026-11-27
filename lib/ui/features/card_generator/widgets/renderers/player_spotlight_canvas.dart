import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/card_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../primitives/brand_footer.dart';
import '../../../../../domain/models/card_data.dart';
import '../primitives/broadcast_background.dart';
import '../editable_canvas_text.dart';

class PlayerSpotlightCanvas extends StatelessWidget {
  const PlayerSpotlightCanvas({
    super.key,
    required this.data,
    required this.config,
  });
  final PlayerSpotlight data;
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'PLAYER SPOTLIGHT',
                    style: CardFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                if (data.rating > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: config.theme.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ÃƒÂ¢Ã‚Â­Ã‚Â ${data.rating.toStringAsFixed(1)}',
                      style: CardFonts.jetBrainsMono(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            EditableCanvasText(
              data.playerName,
              fieldKey: 'playerName',
              style: config.font(
                color: Colors.white,
                fontSize: 26 * fontMultiplier,
                fontWeight: FontWeight.w900,
                height: 1.1,
                shadows: config.textShadowRadius > 0
                    ? [
                        Shadow(
                          color: config.textShadowColor,
                          blurRadius: config.textShadowRadius,
                        ),
                      ]
                    : null,
              ),
              maxLines: 3,
              minFontSize: 12,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (data.club != 'N/A') ...[
                  Flexible(
                    child: Text(
                      data.club,
                      overflow: TextOverflow.ellipsis,
                      style: config.font(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (data.position != 'N/A')
                    Text(
                      ' • ',
                      style: config.font(color: Colors.white54, fontSize: 13),
                    ),
                ],
                if (data.position != 'N/A')
                  Flexible(
                    child: Text(
                      data.position,
                      overflow: TextOverflow.ellipsis,
                      style: config.font(color: Colors.white70, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Stat Pills Row
            if (data.goals > 0 || data.assists > 0 || data.appearances > 0) ...[
              Row(
                children: [
                  if (data.goals > 0) ...[
                    _buildStatBox('${data.goals}', 'GOALS'),
                    const SizedBox(width: 8),
                  ],
                  if (data.assists > 0) ...[
                    _buildStatBox('${data.assists}', 'ASSISTS'),
                    const SizedBox(width: 8),
                  ],
                  if (data.appearances > 0) ...[
                    _buildStatBox('${data.appearances}', 'APPS'),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (data.keyAction != 'N/A' && data.keyAction.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.keyAction,
                  style: config.font(color: Colors.white70, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 16),
            BrandFooter(config: config, fallback: 'Spotlight'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: CardFonts.jetBrainsMono(
              color: config.theme.warning,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: CardFonts.jetBrainsMono(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
