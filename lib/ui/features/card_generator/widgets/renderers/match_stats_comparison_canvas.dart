import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/card_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../primitives/primitives.dart';
import '../../../../../domain/models/card_data.dart';

class MatchStatsComparisonCanvas extends StatelessWidget {
  const MatchStatsComparisonCanvas({
    super.key,
    required this.data,
    required this.config,
  });
  final MatchStatsComparison data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final fontMultiplier = config.fontSizeMultiplier;
    final stats = data.stats;

    return BroadcastBackground(
      config: config,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'MATCH COMPARISON',
                style: CardFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.homeTeam,
                    style: config.font(
                      color: Colors.white,
                      fontSize: 16 * fontMultiplier,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'VS',
                    style: CardFonts.jetBrainsMono(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    data.awayTeam,
                    style: config.font(
                      color: Colors.white,
                      fontSize: 16 * fontMultiplier,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
                child: stats.isNotEmpty
                    ? ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.length.clamp(0, 5),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final s = stats[index];
                          return StatBar(
                            label: s.label,
                            homeValue: s.homeValue,
                            awayValue: s.awayValue,
                            homeColor: config.theme.accent,
                            awayColor: config.theme.alert,
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          data.subtext.isNotEmpty
                              ? data.subtext
                              : 'Match Statistics',
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
            BrandFooter(config: config, fallback: 'Match Stats'),
          ],
        ),
      ),
    );
  }
}
