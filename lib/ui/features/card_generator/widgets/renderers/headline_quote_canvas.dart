import 'package:flutter/material.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../domain/services/card_data_normalizer.dart';
import '../../../../../config/theme/card_type.dart';
import '../card_slot.dart';
import '../editable_canvas_text.dart';
import '../primitives/primitives.dart';

/// Poster-family quote card: one brand mark, a short weighty quote and a
/// strong photo. Giant type behind a cutout is supplied by the background
/// renderer when `ImagePosition.cutout` is selected.
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
    final quoteSize = density == ContentDensity.compact
        ? 30.0
        : (density == ContentDensity.normal ? 38.0 : 46.0);

    return BroadcastBackground(
      config: config,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            EditableCanvasText(
              '“$quoteText”',
              fieldKey: cleanSubtext.isNotEmpty ? 'subtext' : 'headline',
              style: CardType.display.copyWith(
                fontSize: quoteSize * fontMultiplier,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                height: 1.08,
                letterSpacing: 0,
              ),
              maxLines: density == ContentDensity.compact ? 4 : 5,
              minFontSize: 16,
            ),
            const SizedBox(height: 20),
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
            BrandFooter(
              config: config,
              fallback: 'Quote of the Day',
              showCrest: true,
              trailing: CardDataNormalizer.cleanValue(data.relatedTeams),
            ),
          ],
        ),
      ),
    );
  }
}
