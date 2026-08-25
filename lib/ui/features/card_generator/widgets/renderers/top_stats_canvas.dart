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
    return Container(
      decoration: BoxDecoration(gradient: GradientBuilder.vertical(colors)),
      child: Stack(
        children: [
          if (config.showScrim) Positioned.fill(child: Container(decoration: BoxDecoration(gradient: GradientBuilder.scrimFor(config.scrimType, config.overlayOpacity)))),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)), child: Text('Top Stats', style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize:10, letterSpacing:1))),
                const SizedBox(height:12),
                Text(data.headline, style: GoogleFonts.inter(color: Colors.white, fontSize: 22 * config.fontSizeMultiplier, fontWeight: FontWeight.w900, height:1.1, shadows: config.textShadowRadius>0?[Shadow(color: config.textShadowColor, blurRadius: config.textShadowRadius)]:null)),
                const SizedBox(height:8),
                if (data.subtext.isNotEmpty && data.subtext!='N/A') Text(data.subtext, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                if (data.microStat!=null && data.microStat!='N/A') Padding(padding: const EdgeInsets.only(top:10), child: Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Text(data.microStat!, style: const TextStyle(color: Colors.black, fontSize:12, fontWeight: FontWeight.w800)))),
                const Spacer(),
                Text('Oreamnos', style: GoogleFonts.jetBrainsMono(color: Colors.white.withValues(alpha: 0.7), fontSize:11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
