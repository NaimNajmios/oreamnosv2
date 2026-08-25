import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class InjuryReportCanvas extends StatelessWidget {
  const InjuryReportCanvas({super.key, required this.data, required this.config});
  final InjuryReport data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;
    final injuries = data.injuries;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medical_services_rounded, color: Colors.redAccent, size: 12),
                          const SizedBox(width: 4),
                          Text('INJURY UPDATE', style: GoogleFonts.jetBrainsMono(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (data.nextMatch != 'N/A')
                      Text('Next: ${data.nextMatch}', style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data.teamName,
                  style: GoogleFonts.inter(
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
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: injuries.isNotEmpty
                        ? ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: injuries.length.clamp(0, 4),
                            separatorBuilder: (_, _) => const Divider(height: 10, color: Colors.white12),
                            itemBuilder: (context, index) {
                              final item = injuries[index];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.playerName,
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          item.injury,
                                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.status.toLowerCase().contains('out') || item.isLongTerm
                                          ? Colors.redAccent.withValues(alpha: 0.2)
                                          : Colors.amberAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.recoveryPercentage != 'N/A' ? item.recoveryPercentage : item.status,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: item.status.toLowerCase().contains('out') || item.isLongTerm ? Colors.redAccent : Colors.amberAccent,
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
                              data.subtext.isNotEmpty ? data.subtext : 'Squad Fitness Update',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Oreamnos Injury Watch', style: GoogleFonts.jetBrainsMono(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
