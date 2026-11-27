import 'package:flutter/material.dart';

import '../../../../../config/theme/card_type.dart';
import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../domain/models/card_template.dart';
import '../../../../../domain/services/card_data_normalizer.dart';
import '../card_slot.dart';
import '../editable_canvas_text.dart';
import '../primitives/primitives.dart';

/// One renderer for the broadcast "moment" family.
///
/// The shared [Moment] data shape keeps AI extraction to a single schema; the
/// layout switches on the selected template.
class MomentCanvas extends StatelessWidget {
  const MomentCanvas({super.key, required this.data, required this.config});

  final Moment data;
  final CardConfig config;

  String _clean(String value) => CardDataNormalizer.cleanValue(value);

  String get _kicker => switch (config.template) {
    CardTemplate.goal => 'GOAL',
    CardTemplate.fullTime => 'FULL TIME',
    CardTemplate.nextUp => 'NEXT UP',
    CardTemplate.substitution => 'SUBSTITUTION',
    _ => 'MOMENT',
  };

  String get _hero {
    switch (config.template) {
      case CardTemplate.goal:
        return _clean(data.headline).isEmpty
            ? 'GOAL'
            : _clean(data.headline).toUpperCase();
      case CardTemplate.fullTime:
        return _clean(data.score).isEmpty ? 'FULL TIME' : _clean(data.score);
      case CardTemplate.nextUp:
        final home = _clean(data.homeTeam);
        final away = _clean(data.awayTeam);
        return home.isEmpty && away.isEmpty
            ? _clean(data.headline)
            : '$home  vs  $away';
      case CardTemplate.substitution:
        return _clean(data.minute).isEmpty ? 'SUB' : _clean(data.minute);
      default:
        return _clean(data.headline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = config.fontSizeMultiplier;
    final detail = _clean(data.subtext);
    final trailing = _clean(data.competition).isNotEmpty
        ? _clean(data.competition)
        : _clean(data.venue);

    return BroadcastBackground(
      config: config,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _kicker,
                  style: CardTypography.kicker(
                    color: config.theme.warning,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                CardSlot(
                  value: data.minute,
                  fieldKey: 'minute',
                  child: Text(
                    _clean(data.minute),
                    style: CardTypography.meta(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _hero,
                style: CardType.hero.copyWith(
                  fontSize: 72 * multiplier,
                  color: config.theme.accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CardSlot(
              value: data.playerName,
              fieldKey: 'playerName',
              child: Text(
                _clean(data.playerName),
                style: CardType.title.copyWith(
                  color: Colors.white,
                  fontSize: 26 * multiplier,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 6),
              EditableCanvasText(
                detail,
                fieldKey: 'subtext',
                style: CardTypography.body(color: Colors.white70),
                maxLines: 3,
                minFontSize: 12,
              ),
            ],
            if (config.template == CardTemplate.substitution) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _clean(data.playersOut),
                      style: CardTypography.meta(color: Colors.white60),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _clean(data.playersIn),
                      style: CardTypography.meta(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            BrandFooter(
              config: config,
              fallback: 'Match Moment',
              showCrest: true,
              trailing: trailing.isEmpty ? null : trailing,
            ),
          ],
        ),
      ),
    );
  }
}
