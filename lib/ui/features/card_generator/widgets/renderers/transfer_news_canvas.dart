import 'package:flutter/material.dart';

import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../domain/services/card_data_normalizer.dart';
import '../card_slot.dart';
import '../editable_canvas_text.dart';
import '../primitives/primitives.dart';

class TransferNewsCanvas extends StatelessWidget {
  const TransferNewsCanvas({
    super.key,
    required this.data,
    required this.config,
  });

  final TransferNews data;
  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final fontMultiplier = config.fontSizeMultiplier;
    final density = ContentFitResolver.resolve(
      hero: data.playerName,
      headline: '${data.fromTeam} ${data.toTeam}',
      subtext: data.quote,
    );

    final actionClean = CardDataNormalizer.cleanValue(data.action);
    final hasQuote = CardDataNormalizer.cleanValue(data.quote).isNotEmpty;
    final hasFee = CardDataNormalizer.cleanValue(data.fee).isNotEmpty;
    final hasContract = CardDataNormalizer.cleanValue(data.contractLength)
        .isNotEmpty;

    return BroadcastBackground(
      config: config,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Kicker Bar
            Row(
              children: [
                Text(
                  actionClean.isNotEmpty
                      ? actionClean.toUpperCase()
                      : 'TRANSFER NEWS',
                  style: CardTypography.kicker(
                    color: Colors.greenAccent,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                CardSlot(
                  value: data.feeCategory,
                  fieldKey: 'feeCategory',
                  child: Text(
                    data.feeCategory.toUpperCase(),
                    style: CardTypography.meta(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Hero: Player Name with Broadcast Glow
            EditableCanvasText(
              data.playerName,
              fieldKey: 'playerName',
              enableGlow: true,
              style: config
                  .font(
                    fontSize:
                        (density == ContentDensity.compact ? 36 : 48) *
                        fontMultiplier,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: 0.5,
                  )
                  .merge(
                    const TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              maxLines: density == ContentDensity.compact ? 2 : 3,
              minFontSize: 20,
            ),

            const SizedBox(height: 16),

            // Transfer Route (Seamless without borders)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FROM',
                        style: CardTypography.kicker(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      EditableCanvasText(
                        data.fromTeam != 'N/A' ? data.fromTeam : 'Current Club',
                        fieldKey: 'fromTeam',
                        style: config.font(
                          fontSize: 16 * fontMultiplier,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        minFontSize: 11,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SubjectGlow(
                    size: 36,
                    color: Colors.greenAccent.withValues(alpha: 0.35),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TO',
                        style: CardTypography.kicker(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      EditableCanvasText(
                        data.toTeam != 'N/A' ? data.toTeam : 'New Club',
                        fieldKey: 'toTeam',
                        style: config.font(
                          fontSize: 16 * fontMultiplier,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        minFontSize: 11,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (hasFee || hasContract) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (hasFee)
                    Text(
                      data.fee,
                      style: CardTypography.hero.copyWith(
                        fontSize: 28 * fontMultiplier,
                        color: Colors.amberAccent,
                        shadows: const [
                          Shadow(
                            color: Color(0x99000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  if (hasFee && hasContract) const SizedBox(width: 12),
                  if (hasContract)
                    Text(
                      '${data.contractLength} deal',
                      style: CardTypography.meta(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ],

            if (hasQuote && density != ContentDensity.compact) ...[
              const SizedBox(height: 12),
              const FadeHairline(opacity: 0.3),
              const SizedBox(height: 10),
              EditableCanvasText(
                '“${data.quote}”',
                fieldKey: 'quote',
                style: CardTypography.body(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: density == ContentDensity.spacious ? 3 : 2,
                minFontSize: 10,
              ),
            ],

            const SizedBox(height: 14),

            // Footer
            Row(
              children: [
                Text(
                  config.brandName?.isNotEmpty == true
                      ? config.brandName!
                      : (config.brandHandle?.isNotEmpty == true
                            ? config.brandHandle!
                            : 'Transfer Center'),
                  style: CardTypography.meta(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                CardSlot(
                  value: data.transferType,
                  fieldKey: 'transferType',
                  child: Text(
                    data.transferType.toUpperCase(),
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
    );
  }
}
