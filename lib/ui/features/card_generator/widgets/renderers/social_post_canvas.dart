import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../data/services/gradient_builder.dart';
import '../editable_canvas_text.dart';

class SocialPostCanvas extends StatelessWidget {
  const SocialPostCanvas({super.key, required this.data, required this.config});
  final SocialPost data;
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
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Social Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        data.name.isNotEmpty && data.name != 'N/A'
                            ? data.name[0].toUpperCase()
                            : '⚽',
                        style: config.font(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  data.name != 'N/A' && data.name.isNotEmpty
                                      ? data.name
                                      : (config.brandName?.isNotEmpty == true
                                          ? config.brandName!
                                          : 'Verified Account'),
                                  style: config.font(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    applyMultiplier: false,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (data.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.blueAccent,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          EditableCanvasText(
                            data.handle != 'N/A'
                                ? data.handle
                                : (config.brandHandle?.isNotEmpty == true
                                    ? config.brandHandle!
                                    : '@creator'),
                            fieldKey: 'microStat',
                            autoSize: false,
                            style: config.font(
                              color: Colors.white70,
                              fontSize: 11,
                              applyMultiplier: false,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    if (data.mediaType != 'N/A')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data.mediaType.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Post Content
                EditableCanvasText(
                  data.content,
                  fieldKey: 'headline',
                  autoSize: false,
                  style: config.font(
                    color: Colors.white,
                    fontSize: 18 * fontMultiplier,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    shadows: config.textShadowRadius > 0
                        ? [
                            Shadow(
                              color: config.textShadowColor,
                              blurRadius: config.textShadowRadius,
                            ),
                          ]
                        : null,
                  ),
                  maxLines: 6,
                ),
                const Spacer(),
                // Metrics
                if (data.metrics != 'N/A' && data.metrics.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: EditableCanvasText(
                      data.metrics,
                      fieldKey: 'subtext',
                      autoSize: false,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  config.brandName?.isNotEmpty == true
                        ? config.brandName!
                        : (config.brandHandle?.isNotEmpty == true
                            ? config.brandHandle!
                            : 'Social Feed'),
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
