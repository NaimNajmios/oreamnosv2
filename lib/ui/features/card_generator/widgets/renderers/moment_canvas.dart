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
    CardTemplate.kitReveal => 'KIT REVEAL',
    CardTemplate.signing => 'SIGNING',
    CardTemplate.birthday => 'HAPPY BIRTHDAY',
    CardTemplate.milestone => 'MILESTONE',
    CardTemplate.playerOfTheMatch => 'PLAYER OF THE MATCH',
    CardTemplate.profileQA => 'PLAYER Q&A',
    CardTemplate.seasonReview => 'SEASON REVIEW',
    CardTemplate.statsDashboard => 'DATA VIZ',
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
      case CardTemplate.kitReveal:
        return _clean(data.kit).isEmpty
            ? _clean(data.headline)
            : _clean(data.kit).toUpperCase();
      case CardTemplate.signing:
      case CardTemplate.playerOfTheMatch:
        return _clean(data.playerName).isEmpty
            ? _clean(data.headline)
            : _clean(data.playerName);
      case CardTemplate.birthday:
        return _clean(data.years).isEmpty
            ? _clean(data.headline)
            : '${_clean(data.years)} YEARS';
      case CardTemplate.milestone:
        return _clean(data.appearances).isEmpty
            ? _clean(data.headline)
            : _clean(data.appearances);
      default:
        return _clean(data.headline);
    }
  }

  String get _extraDetail {
    switch (config.template) {
      case CardTemplate.kitReveal:
      case CardTemplate.signing:
        return _clean(data.awayTeam);
      case CardTemplate.birthday:
        return _clean(data.appearances);
      case CardTemplate.milestone:
        return _clean(data.years);
      case CardTemplate.playerOfTheMatch:
        return _clean(data.nominees);
      case CardTemplate.profileQA:
        return _clean(data.questions);
      case CardTemplate.seasonReview:
        return _clean(data.score);
      default:
        return '';
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
                Flexible(
                  child: Text(
                    _kicker,
                    overflow: TextOverflow.ellipsis,
                    style: CardTypography.kicker(
                      color: config.theme.warning,
                      fontSize: 12,
                    ),
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
            if (config.template == CardTemplate.statsDashboard) ...[
              const SizedBox(height: 8),
              if (DataVizInput.integers(data.positions).length >= 2)
                BumpChart(positions: data.positions, height: 56),
              Row(
                children: [
                  RadarChart(metrics: data.metrics, size: 84),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        XgTimeline(points: data.xg, height: 48),
                        const SizedBox(height: 4),
                        ShotMap(shots: data.shots, height: 64),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (config.template == CardTemplate.seasonReview) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  StatTile(
                    label: 'Goals',
                    value: _clean(data.score).isEmpty
                        ? '0'
                        : _clean(data.score),
                    accent: config.theme.accent,
                  ),
                  const SizedBox(width: 8),
                  StatTile(
                    label: 'Apps',
                    value: _clean(data.appearances).isEmpty
                        ? '0'
                        : _clean(data.appearances),
                    accent: config.theme.warning,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FormPills(form: _clean(data.subtext)),
            ],
            if (_extraDetail.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _extraDetail,
                style: CardTypography.meta(color: config.theme.warning),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
