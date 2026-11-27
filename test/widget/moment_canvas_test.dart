import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_state.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/renderers/moment_canvas.dart';

void main() {
  final cases = {
    CardTemplate.goal: 'GOAL',
    CardTemplate.fullTime: '2-1',
    CardTemplate.nextUp: 'JDT  vs  SELANGOR',
    CardTemplate.substitution: "63'",
    CardTemplate.kitReveal: 'HOME',
    CardTemplate.signing: 'Salah',
    CardTemplate.birthday: '32 YEARS',
    CardTemplate.milestone: '100',
    CardTemplate.playerOfTheMatch: 'Salah',
    CardTemplate.profileQA: 'GOAL',
    CardTemplate.seasonReview: 'GOAL',
  };

  for (final entry in cases.entries) {
    testWidgets('${entry.key.name} renders its hero', (tester) async {
      final data = CardData.moment(
        headline: 'GOAL',
        subtext: 'Salah scores',
        minute: "63'",
        score: '2-1',
        playerName: 'Salah',
        homeTeam: 'JDT',
        awayTeam: 'SELANGOR',
        kit: 'HOME',
        years: '32',
        appearances: '100',
        suggestedTemplate: entry.key,
      ) as Moment;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cardGeneratorViewModelProvider.overrideWith(
              () => _FakeCardGeneratorViewModel(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 380,
                height: 475,
                child: MomentCanvas(
                  data: data,
                  config: CardConfig(template: entry.key),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(entry.value), findsWidgets);
    });
  }
}

class _FakeCardGeneratorViewModel extends CardGeneratorViewModel {
  _FakeCardGeneratorViewModel();

  @override
  CardGeneratorState build() => const CardGeneratorState();
}
