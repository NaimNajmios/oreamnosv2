import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';

class HeadlineQuoteCanvas extends StatelessWidget {
  const HeadlineQuoteCanvas({super.key, required this.data, required this.config});
  final HeadlineQuote data;
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
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.category != 'N/A')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
                    child: Text(data.category.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                const Spacer(),
                // Large Quote Mark
                Text(
                  '“',
                  style: GoogleFonts.lora(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 64,
                    height: 0.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  data.subtext.isNotEmpty && data.subtext != 'N/A' ? data.subtext : data.headline,
                  style: GoogleFonts.lora(
                    color: Colors.white,
                    fontSize: 20 * fontMultiplier,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                    shadows: config.textShadowRadius > 0 ? [Shadow(color: config.textShadowColor, blurRadius: config.textShadowRadius)] : null,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Author Byline
                Row(
                  children: [
                    Container(width: 32, height: 2, color: Colors.amberAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.quoteAuthor != 'N/A' ? data.quoteAuthor : data.headline,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (data.authorTitle != 'N/A')
                            Text(
                              data.authorTitle,
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text('Oreamnos Quote', style: GoogleFonts.jetBrainsMono(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
