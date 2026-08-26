import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class DetailedScoreboardCanvas extends StatelessWidget {
  const DetailedScoreboardCanvas({
    super.key,
    required this.data,
    required this.config,
  });
  final DetailedScoreboard data;
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Tag / Status
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
                            : 'FULL TIME',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (data.matchStatus != 'N/A')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data.matchStatus,
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Scoreboard Banner
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              data.homeTeam,
                              style: config.font(
                                color: Colors.white,
                                fontSize: 16 * fontMultiplier,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            if (data.homeScorers != 'N/A' &&
                                data.homeScorers.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                data.homeScorers,
                                style: config.font(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${data.homeScore} - ${data.awayScore}',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: 32 * fontMultiplier,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              data.awayTeam,
                              style: config.font(
                                color: Colors.white,
                                fontSize: 16 * fontMultiplier,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            if (data.awayScorers != 'N/A' &&
                                data.awayScorers.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                data.awayScorers,
                                style: config.font(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.possession != 'N/A' ||
                    data.shotsOnTarget != 'N/A') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (data.possession != 'N/A')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Possession: ${data.possession}',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (data.possession != 'N/A' &&
                          data.shotsOnTarget != 'N/A')
                        const SizedBox(width: 8),
                      if (data.shotsOnTarget != 'N/A')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Shots on Target: ${data.shotsOnTarget}',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Text(
                      config.brandName?.isNotEmpty == true
                        ? config.brandName!
                        : (config.brandHandle?.isNotEmpty == true
                            ? config.brandHandle!
                            : 'Scoreboard'),
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    if (data.attendance != 'N/A')
                      Text(
                        'Att: ${data.attendance}',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
