import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../domain/services/card_data_normalizer.dart';
import '../card_slot.dart';
import '../editable_canvas_text.dart';
import '../primitives/primitives.dart';

class DetailedScoreboardCanvas extends StatelessWidget {
  const DetailedScoreboardCanvas({
    super.key,
    required this.data,
    required this.config,
  });

  final DetailedScoreboard data;
  final CardConfig config;

  double _parseHomePct(String raw) {
    final clean = CardDataNormalizer.cleanValue(raw);
    if (clean.isEmpty) return 0.5;
    final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
    final val = double.tryParse(digits);
    if (val == null) return 0.5;
    if (val > 1.0) return (val / 100).clamp(0.1, 0.9);
    return val.clamp(0.1, 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final fontMultiplier = config.fontSizeMultiplier;
    final density = ContentFitResolver.resolve(
      hero: '${data.homeScore} - ${data.awayScore}',
      headline: '${data.homeTeam} ${data.awayTeam}',
      subtext: '${data.homeScorers} ${data.awayScorers}',
    );

    final compClean = CardDataNormalizer.cleanValue(data.competition);
    final hasHomeScorers = CardDataNormalizer.cleanValue(data.homeScorers)
        .isNotEmpty;
    final hasAwayScorers = CardDataNormalizer.cleanValue(data.awayScorers)
        .isNotEmpty;
    final hasPossession = CardDataNormalizer.cleanValue(data.possession)
        .isNotEmpty;
    final hasShots = CardDataNormalizer.cleanValue(data.shotsOnTarget)
        .isNotEmpty;

    final homeColor = config.colorPair.isNotEmpty
        ? config.colorPair.first
        : Colors.blueAccent;
    final awayColor = config.colorPair.length > 1
        ? config.colorPair.last
        : Colors.redAccent;
    final homePct = _parseHomePct(data.possession);

    return BroadcastBackground(
      config: config,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Competition Header
            Row(
              children: [
                Text(
                  compClean.isNotEmpty
                      ? compClean.toUpperCase()
                      : 'MATCH RESULT',
                  style: CardTypography.kicker(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                CardSlot(
                  value: data.matchStatus,
                  fieldKey: 'matchStatus',
                  child: Text(
                    data.matchStatus.toUpperCase(),
                    style: CardTypography.kicker(
                      color: Colors.greenAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Hero Scoreboard (No strokes, pure typography & depth)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Home Team
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      EditableCanvasText(
                        data.homeTeam,
                        fieldKey: 'homeTeam',
                        textAlign: TextAlign.center,
                        enableGlow: true,
                        style: config
                            .font(
                              fontSize: 18 * fontMultiplier,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.05,
                            )
                            .merge(
                              const TextStyle(
                                fontFamily: 'BarlowCondensed',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        maxLines: 2,
                        minFontSize: 11,
                      ),
                      if (hasHomeScorers &&
                          density != ContentDensity.compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.homeScorers,
                          style: CardTypography.meta(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Hero Score (AutoSizeText with minFontSize constraint)
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AutoSizeText(
                      '${data.homeScore} – ${data.awayScore}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      minFontSize: 24,
                      style: CardTypography.hero.copyWith(
                        fontSize:
                            (density == ContentDensity.compact ? 44 : 54) *
                            fontMultiplier,
                        letterSpacing: 1,
                        shadows: const [
                          Shadow(
                            color: Color(0xB3000000),
                            blurRadius: 28,
                            offset: Offset(0, 6),
                          ),
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Away Team
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      EditableCanvasText(
                        data.awayTeam,
                        fieldKey: 'awayTeam',
                        textAlign: TextAlign.center,
                        enableGlow: true,
                        style: config
                            .font(
                              fontSize: 18 * fontMultiplier,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.05,
                            )
                            .merge(
                              const TextStyle(
                                fontFamily: 'BarlowCondensed',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        maxLines: 2,
                        minFontSize: 11,
                      ),
                      if (hasAwayScorers &&
                          density != ContentDensity.compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.awayScorers,
                          style: CardTypography.meta(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Seamless Glowing Possession Bar
            if (hasPossession) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [homeColor, homeColor, awayColor, awayColor],
                          stops: [
                            0.0,
                            (homePct - 0.02).clamp(0.0, 1.0),
                            (homePct + 0.02).clamp(0.0, 1.0),
                            1.0,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: homeColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(homePct * 100).toInt()}% POSSESSION',
                          style: CardTypography.kicker(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          '${((1 - homePct) * 100).toInt()}%',
                          style: CardTypography.kicker(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Match Metrics row (Negative space instead of boxes)
            if (hasShots || data.corners != 'N/A' || data.attendance != 'N/A')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasShots) ...[
                    Text(
                      'SHOTS: ${data.shotsOnTarget}',
                      style: CardTypography.meta(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  if (hasShots && data.corners != 'N/A') ...[
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.white38)),
                    const SizedBox(width: 8),
                    Text(
                      'CORNERS: ${data.corners}',
                      style: CardTypography.meta(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),

            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                Text(
                  config.brandName?.isNotEmpty == true
                      ? config.brandName!
                      : (config.brandHandle?.isNotEmpty == true
                            ? config.brandHandle!
                            : 'Scoreboard'),
                  style: CardTypography.meta(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                CardSlot(
                  value: data.attendance,
                  fieldKey: 'attendance',
                  child: Text(
                    'Att: ${data.attendance}',
                    style: CardTypography.meta(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
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
