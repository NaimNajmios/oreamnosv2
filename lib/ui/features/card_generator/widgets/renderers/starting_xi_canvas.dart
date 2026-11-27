import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/card_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../primitives/broadcast_background.dart';
import '../primitives/brand_footer.dart';
import '../primitives/glass_tile.dart';
import '../../../../../domain/models/card_data.dart';

class StartingXICanvas extends StatelessWidget {
  const StartingXICanvas({super.key, required this.data, required this.config});
  final StartingXI data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final fontMultiplier = config.fontSizeMultiplier;
    final players = data.starters;

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
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'STARTING XI',
                    style: CardFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                if (data.formation != 'N/A')
                  GlassTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Text(
                      data.formation,
                      style: CardFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.teamName,
              style: config.font(
                color: Colors.white,
                fontSize: 22 * fontMultiplier,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            if (data.manager != 'N/A') ...[
              const SizedBox(height: 4),
              Text(
                'Manager: ${data.manager}',
                style: config.font(color: Colors.white70, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: players.isNotEmpty
                    ? GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 4.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 4,
                            ),
                        itemCount: players.length.clamp(0, 11),
                        itemBuilder: (context, index) {
                          final p = players[index];
                          return Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  p.number,
                                  style: CardFonts.jetBrainsMono(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: config.font(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                              : 'Lineup Announced',
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
            Row(
              children: [
                BrandFooter(
                  config: config,
                  fallback: 'Lineup',
                  showCrest: true,
                ),
                const Spacer(),
                if (data.subs.isNotEmpty)
                  Text(
                    '${data.subs.length} Subs',
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
