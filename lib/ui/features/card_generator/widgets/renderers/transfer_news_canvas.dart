import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class TransferNewsCanvas extends StatelessWidget {
  const TransferNewsCanvas({super.key, required this.data, required this.config});
  final TransferNews data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = config.colorPair;
    final fontMultiplier = config.fontSizeMultiplier;

    return Container(
      decoration: BoxDecoration(gradient: GradientBuilder.vertical(colors)),
      child: Stack(
        children: [
          if (config.showScrim)
            Positioned.fill(
              child: Container(decoration: BoxDecoration(gradient: GradientBuilder.scrimFor(config.scrimType, config.overlayOpacity))),
            ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(16)),
                      child: Text('TRANSFER ALERT', style: GoogleFonts.jetBrainsMono(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                    const Spacer(),
                    if (data.feeCategory != 'N/A')
                      Text(data.feeCategory, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                const Spacer(),
                Text(
                  data.playerName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 26 * fontMultiplier,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    shadows: config.textShadowRadius > 0 ? [Shadow(color: config.textShadowColor, blurRadius: config.textShadowRadius)] : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Transfer Route: From -> To
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FROM', style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700)),
                            Text(data.fromTeam != 'N/A' ? data.fromTeam : 'Current Club', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, color: Colors.greenAccent, size: 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('TO', style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700)),
                            Text(data.toTeam != 'N/A' ? data.toTeam : 'New Club', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Fee & Contract Details
                Row(
                  children: [
                    if (data.fee != 'N/A')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text('Fee: ${data.fee}', style: GoogleFonts.jetBrainsMono(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    if (data.fee != 'N/A' && data.contractLength != 'N/A') const SizedBox(width: 8),
                    if (data.contractLength != 'N/A')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                        child: Text('${data.contractLength} deal', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const Spacer(),
                Text('Oreamnos Transfer Center', style: GoogleFonts.jetBrainsMono(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
