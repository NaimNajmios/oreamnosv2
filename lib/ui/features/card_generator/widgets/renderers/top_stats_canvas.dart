import 'package:flutter/material.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../primitives/primitives.dart';

class TopStatsCanvas extends StatelessWidget {
  const TopStatsCanvas({super.key, required this.data, required this.config});

  final TopStats data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final fontMultiplier = config.fontSizeMultiplier;
    final stats = data.stats;
    final density = ContentFitResolver.resolve(
      hero: stats.map((s) => s.value).join(' '),
      headline: data.matchContext,
      listItems: stats.length,
    );

    final maxItems = density == ContentDensity.compact
        ? 2
        : (density == ContentDensity.normal ? 3 : 4);
    final visibleStats = stats.take(maxItems).toList();

    return BroadcastBackground(
      config: config,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Kicker & Match Context
            Row(
              children: [
                Text(
                  'TOP STATS',
                  style: CardTypography.kicker(
                    color: Colors.amberAccent,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (data.matchContext != 'N/A' && data.matchContext.isNotEmpty)
                  Text(
                    data.matchContext.toUpperCase(),
                    style: CardTypography.meta(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const FadeHairline(opacity: 0.2),
            const Spacer(),

            // Stat Column with Hero Values (Negative space separation)
            if (visibleStats.isNotEmpty)
              ...visibleStats.asMap().entries.map((entry) {
                final index = entry.key;
                final s = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < visibleStats.length - 1
                        ? (density == ContentDensity.compact ? 12 : 18)
                        : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Hero Number
                      Text(
                        s.value,
                        style: CardTypography.hero.copyWith(
                          fontSize:
                              (density == ContentDensity.compact ? 42 : 56) *
                              fontMultiplier,
                          color: Colors.amberAccent,
                          shadows: const [
                            Shadow(
                              color: Color(0x99000000),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Label & Context
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.label.toUpperCase(),
                              style: CardTypography.kicker(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (s.context.isNotEmpty && s.context != 'N/A') ...[
                              const SizedBox(height: 2),
                              Text(
                                s.context,
                                style: CardTypography.meta(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              Center(
                child: Text(
                  data.subtext.isNotEmpty ? data.subtext : 'Top Performance',
                  style: CardTypography.body(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),
            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                Text(
                  config.brandName?.isNotEmpty == true
                      ? config.brandName!
                      : (config.brandHandle?.isNotEmpty == true
                            ? config.brandHandle!
                            : 'Stats Center'),
                  style: CardTypography.meta(
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
