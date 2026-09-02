import 'package:flutter/material.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../editable_canvas_text.dart';
import '../primitives/primitives.dart';

class HeadlineQuoteCanvas extends StatelessWidget {
  const HeadlineQuoteCanvas({
    super.key,
    required this.data,
    required this.config,
  });

  final HeadlineQuote data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final fontMultiplier = config.fontSizeMultiplier;
    final quoteText = data.subtext.isNotEmpty && data.subtext != 'N/A'
        ? data.subtext
        : data.headline;
    final hasAuthor = data.quoteAuthor.isNotEmpty && data.quoteAuthor != 'N/A';
    final hasCategory = data.category.isNotEmpty && data.category != 'N/A';

    final density = ContentFitResolver.resolve(
      hero: quoteText,
      headline: data.quoteAuthor,
      subtext: data.authorTitle,
    );

    return BroadcastBackground(
      config: config,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Giant Translucent Background Quote Glyph (Layered Ambient Depth)
          Positioned(
            top: 24,
            left: 16,
            child: IgnorePointer(
              child: Text(
                '“',
                style: TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontWeight: FontWeight.w900,
                  fontSize: 180,
                  height: 0.8,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Kicker
                if (hasCategory)
                  Text(
                    data.category.toUpperCase(),
                    style: CardTypography.kicker(
                      color: Colors.amberAccent,
                      fontSize: 11,
                    ),
                  ),

                const Spacer(),

                // Main Quote in Headline Scale with Broadcast Glow
                EditableCanvasText(
                  '“$quoteText”',
                  fieldKey: data.subtext.isNotEmpty && data.subtext != 'N/A'
                      ? 'subtext'
                      : 'headline',
                  enableGlow: true,
                  style: config
                      .font(
                        fontSize:
                            (density == ContentDensity.compact
                                ? 26
                                : (density == ContentDensity.normal
                                      ? 32
                                      : 38)) *
                            fontMultiplier,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        height: 1.15,
                        letterSpacing: 0.2,
                      )
                      .merge(
                        const TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  maxLines: density == ContentDensity.compact ? 4 : 6,
                  minFontSize: 16,
                ),

                const SizedBox(height: 20),

                // Author Byline with Dot Separator (No hard border bars)
                if (hasAuthor)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.amberAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EditableCanvasText(
                              data.quoteAuthor,
                              fieldKey: 'quoteAuthor',
                              style: CardTypography.kicker(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              minFontSize: 10,
                            ),
                            if (data.authorTitle.isNotEmpty &&
                                data.authorTitle != 'N/A') ...[
                              const SizedBox(height: 2),
                              Text(
                                data.authorTitle,
                                style: CardTypography.meta(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Footer
                Row(
                  children: [
                    Text(
                      config.brandName?.isNotEmpty == true
                          ? config.brandName!
                          : (config.brandHandle?.isNotEmpty == true
                                ? config.brandHandle!
                                : 'Quote of the Day'),
                      style: CardTypography.meta(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    if (data.relatedTeams.isNotEmpty &&
                        data.relatedTeams != 'N/A')
                      Text(
                        data.relatedTeams,
                        style: CardTypography.meta(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
