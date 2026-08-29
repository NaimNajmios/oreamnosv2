import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class ContractExpiryCanvas extends StatelessWidget {
  const ContractExpiryCanvas({
    super.key,
    required this.data,
    required this.config,
  });
  final ContractExpiry data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;
    final players = data.expiringPlayers;

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
                        color: Colors.amberAccent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.amberAccent,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CONTRACT WATCH',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (data.seasonYear != 'N/A')
                      Text(
                        data.seasonYear,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data.teamName,
                  style: config.font(
                    color: Colors.white,
                    fontSize: 22 * fontMultiplier,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
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
                    child: players.isNotEmpty
                        ? ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: players.length.clamp(0, 4),
                            separatorBuilder: (_, _) => const Divider(
                              height: 10,
                              color: Colors.white12,
                            ),
                            itemBuilder: (context, index) {
                              final p = players[index];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.playerName,
                                          style: config.font(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${p.position} • Val: ${p.marketValue != 'N/A' ? p.marketValue : 'TBD'}',
                                          style: config.font(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Exp: ${p.expiresIn}',
                                      style: GoogleFonts.jetBrainsMono(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
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
                                  : 'Contract Expiry Tracker',
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
                            : 'Contract Tracker'),
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
