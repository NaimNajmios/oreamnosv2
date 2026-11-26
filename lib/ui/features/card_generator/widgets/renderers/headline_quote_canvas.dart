import 'package:flutter/material.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../domain/services/card_data_normalizer.dart';
import '../card_slot.dart';
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
    final cleanSubtext = CardDataNormalizer.cleanValue(data.subtext);
    final cleanHeadline = CardDataNormalizer.cleanValue(data.headline);
    final quoteText = cleanSubtext.isNotEmpty ? cleanSubtext : cleanHeadline;
    final hasAuthor = CardDataNormalizer.cleanValue(data.quoteAuthor)
        .isNotEmpty;

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
                'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“',
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
                CardSlot(
                  value: data.category,
                  fieldKey: 'category',
                  child: Text(
                    data.category.toUpperCase(),
                    style: CardTypography.kicker(
                      color: config.theme.warning,
                      fontSize: 11,
                    ),
                  ),
                ),

                const Spacer(),

                // Main Quote in Headline Scale with Broadcast Glow
                EditableCanvasText(
                  'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“$quoteTextÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â',
                  fieldKey: cleanSubtext.isNotEmpty ? 'subtext' : 'headline',
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
                        decoration: BoxDecoration(
                          color: config.theme.warning,
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
                                data.authorTitle != 'N/A')
                              CardSlot(
                                value: data.authorTitle,
                                fieldKey: 'authorTitle',
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    data.authorTitle,
                                    style: CardTypography.meta(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Footer
                Row(
                  children: [
                    BrandFooter(config: config, fallback: 'Quote of the Day'),
                    const Spacer(),
                    if (data.relatedTeams.isNotEmpty &&
                        data.relatedTeams != 'N/A')
                      CardSlot(
                        value: data.relatedTeams,
                        fieldKey: 'relatedTeams',
                        child: Text(
                          data.relatedTeams,
                          style: CardTypography.meta(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
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
