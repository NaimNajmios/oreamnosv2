import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class RivalryCanvas extends StatelessWidget {
  const RivalryCanvas({super.key, required this.data, required this.config});
  final Rivalry data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;
    final p1Stats = data.player1Stats;
    final p2Stats = data.player2Stats;

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
                    'HEAD-TO-HEAD RIVALRY',
                    style: GoogleFonts.jetBrainsMono(
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
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data.player1Name,
                          style: config.font(
                            color: Colors.white,
                            fontSize: 15 * fontMultiplier,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'VS',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.amberAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data.player2Name,
                          style: config.font(
                            color: Colors.white,
                            fontSize: 15 * fontMultiplier,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (data.headToHead != 'N/A') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Record: ${data.headToHead}',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                    child: p1Stats.isNotEmpty
                        ? ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: p1Stats.length.clamp(0, 4),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final s1 = p1Stats[index];
                              final s2Val = index < p2Stats.length
                                  ? p2Stats[index].value
                                  : '-';
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    s1.value,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    s1.label,
                                    style: config.font(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    s2Val,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white,
                                      fontSize: 13,
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
                                  : 'Rivalry Comparison',
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
                Text(
                  config.brandName?.isNotEmpty == true
                        ? config.brandName!
                        : (config.brandHandle?.isNotEmpty == true
                            ? config.brandHandle!
                            : 'Head to Head'),
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
