import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class TopStatsCanvas extends StatelessWidget {
  const TopStatsCanvas({super.key, required this.data, required this.config});
  final TopStats data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;
    final stats = data.stats;

    return Container(
      decoration: BoxDecoration(
        gradient: config.backgroundImagePath != null
            ? null
            : GradientBuilder.vertical(colors),
      ),
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
                        'MATCH METRICS',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (data.matchContext != 'N/A')
                      Text(
                        data.matchContext,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: stats.isNotEmpty
                      ? GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: stats.length.clamp(0, 4),
                          itemBuilder: (context, index) {
                            final s = stats[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    s.value,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.amberAccent,
                                      fontSize: 26 * fontMultiplier,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.label.toUpperCase(),
                                    style: config.font(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (s.context != 'N/A') ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      s.context,
                                      style: config.font(
                                        color: Colors.white54,
                                        fontSize: 9,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            data.subtext.isNotEmpty
                                ? data.subtext
                                : 'Top Performance Stats',
                            style: config.font(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  config.brandName?.isNotEmpty == true
                      ? config.brandName!
                      : (config.brandHandle?.isNotEmpty == true
                            ? config.brandHandle!
                            : 'Top Stats'),
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
