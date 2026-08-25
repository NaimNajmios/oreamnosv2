import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class MatchStatsComparisonCanvas extends StatelessWidget {
  const MatchStatsComparisonCanvas({super.key, required this.data, required this.config});
  final MatchStatsComparison data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;
    final stats = data.stats;

    return Container(
      decoration: BoxDecoration(gradient: GradientBuilder.vertical(colors)),
      child: Stack(
        children: [
          if (config.showScrim)
            Positioned.fill(
              child: Container(decoration: BoxDecoration(gradient: GradientBuilder.scrimFor(config.scrimType, config.overlayOpacity))),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
                  child: Text('MATCH COMPARISON', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.homeTeam,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16 * fontMultiplier, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('VS', style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      child: Text(
                        data.awayTeam,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16 * fontMultiplier, fontWeight: FontWeight.w800),
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
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: stats.isNotEmpty
                        ? ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: stats.length.clamp(0, 5),
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final s = stats[index];
                              final homeVal = double.tryParse(s.homeValue.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 50.0;
                              final awayVal = double.tryParse(s.awayValue.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 50.0;
                              final total = homeVal + awayVal > 0 ? homeVal + awayVal : 100.0;
                              final homeRatio = (homeVal / total).clamp(0.1, 0.9);

                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.homeValue, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                                      Text(s.label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text(s.awayValue, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: (homeRatio * 100).toInt(),
                                          child: Container(height: 6, color: Colors.blueAccent),
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          flex: ((1.0 - homeRatio) * 100).toInt(),
                                          child: Container(height: 6, color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              data.subtext.isNotEmpty ? data.subtext : 'Match Statistics',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Oreamnos Match Stats', style: GoogleFonts.jetBrainsMono(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
