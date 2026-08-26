import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class MatchPreviewCanvas extends StatelessWidget {
  const MatchPreviewCanvas({
    super.key,
    required this.data,
    required this.config,
  });
  final MatchPreview data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;

    return Container(
      decoration: BoxDecoration(gradient: config.backgroundImagePath != null ? null : GradientBuilder.vertical(colors)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        data.competition != 'N/A'
                            ? data.competition.toUpperCase()
                            : 'MATCHDAY PREVIEW',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (data.kickoffTime != 'N/A')
                      Text(
                        data.kickoffTime,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Matchup Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              data.homeTeam,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16 * fontMultiplier,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            if (data.homeForm != 'N/A') ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Form: ${data.homeForm}',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'VS',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.amberAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              data.awayTeam,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16 * fontMultiplier,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            if (data.awayForm != 'N/A') ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Form: ${data.awayForm}',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.stadium != 'N/A' || data.matchTime != 'N/A') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (data.stadium != 'N/A')
                        Row(
                          children: [
                            const Icon(
                              Icons.stadium_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.stadium,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      if (data.stadium != 'N/A' && data.matchTime != 'N/A')
                        const SizedBox(width: 12),
                      if (data.matchTime != 'N/A')
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.matchTime,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
                const Spacer(),
                Text(
                  'Oreamnos Preview',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
