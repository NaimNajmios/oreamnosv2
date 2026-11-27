import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/card_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../primitives/broadcast_background.dart';
import '../primitives/brand_footer.dart';
import '../../../../../domain/models/card_data.dart';

class AwardNomineeCanvas extends StatelessWidget {
  const AwardNomineeCanvas({
    super.key,
    required this.data,
    required this.config,
  });
  final AwardNominee data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final fontMultiplier = config.fontSizeMultiplier;
    final nominees = data.nominees;

    return BroadcastBackground(
      config: config,
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                    color: config.theme.warning.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: config.theme.warning,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AWARD NOMINEES',
                        style: CardFonts.jetBrainsMono(
                          color: config.theme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (data.category != 'N/A')
                  Text(
                    data.category,
                    style: CardFonts.jetBrainsMono(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.awardName,
              style: config.font(
                color: Colors.white,
                fontSize: 22 * fontMultiplier,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: nominees.isNotEmpty
                    ? ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: nominees.length.clamp(0, 4),
                        separatorBuilder: (_, _) =>
                            const Divider(height: 10, color: Colors.white12),
                        itemBuilder: (context, index) {
                          final nom = nominees[index];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          nom.playerName,
                                          style: config.font(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (nom.isFavorite) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: config.theme.warning,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'FAV',
                                              style: CardFonts.jetBrainsMono(
                                                color: Colors.black,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${nom.club} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${nom.achievement}',
                                      style: config.font(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (nom.odds != 'N/A')
                                Text(
                                  nom.odds,
                                  style: CardFonts.jetBrainsMono(
                                    color: config.theme.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          data.subtext.isNotEmpty
                              ? data.subtext
                              : 'Official Nominees',
                          style: config.font(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            BrandFooter(config: config, fallback: 'Awards'),
          ],
        ),
      ),
    );
  }
}
