import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class TableStandingsCanvas extends StatelessWidget {
  const TableStandingsCanvas({
    super.key,
    required this.data,
    required this.config,
  });
  final TableStandings data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;
    final rows = data.standings;

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
                        'STANDINGS',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (data.matchday != 'N/A')
                      Text(
                        data.matchday,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data.leagueName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20 * fontMultiplier,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header Row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 6,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '#',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'TEAM',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  'PL',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  'GD',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  'PTS',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 8, color: Colors.white12),
                        // Data Rows
                        Expanded(
                          child: rows.isNotEmpty
                              ? ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: rows.length.clamp(0, 6),
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 6,
                                    color: Colors.white10,
                                  ),
                                  itemBuilder: (context, index) {
                                    final r = rows[index];
                                    final isHighlighted =
                                        data.highlightedTeam != 'N/A' &&
                                        r.teamName.toLowerCase().contains(
                                          data.highlightedTeam.toLowerCase(),
                                        );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isHighlighted
                                            ? Colors.white.withValues(
                                                alpha: 0.15,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            child: Text(
                                              '${r.position}',
                                              style: GoogleFonts.jetBrainsMono(
                                                color: r.position <= 4
                                                    ? Colors.amberAccent
                                                    : Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              r.teamName,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: isHighlighted
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 24,
                                            child: Text(
                                              '${r.played}',
                                              style: GoogleFonts.jetBrainsMono(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 24,
                                            child: Text(
                                              '${r.won - r.lost}',
                                              style: GoogleFonts.jetBrainsMono(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              '${r.points}',
                                              style: GoogleFonts.jetBrainsMono(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    data.subtext.isNotEmpty
                                        ? data.subtext
                                        : 'League Table',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Oreamnos League Tracker',
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
