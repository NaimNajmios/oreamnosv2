import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_field_registry.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/services/card_prompt_manager.dart';

void main() {
  const momentTemplates = [
    CardTemplate.goal,
    CardTemplate.fullTime,
    CardTemplate.nextUp,
    CardTemplate.substitution,
  ];

  group('moment templates', () {
    test('are registered as selectable templates with intents', () {
      for (final template in momentTemplates) {
        expect(CardTemplate.all, contains(template));
        expect(template.templateIntent, isNotEmpty);
        expect(CardTemplate.fromIntent(template.templateIntent), template);
      }
    });

    test('share the moment field schema', () {
      for (final template in momentTemplates) {
        final keys = CardFieldRegistry.fieldsFor(template)
            .map((f) => f.key)
            .toSet();
        expect(keys, containsAll(['headline', 'subtext', 'minute', 'score']));
      }
    });

    test('are included in the extraction prompt intents', () {
      final prompt = CardPromptManager.buildSystemPrompt();
      for (final template in momentTemplates) {
        expect(prompt, contains(template.templateIntent));
      }
    });

    test('moment data round-trips and derives its template', () {
      final data = CardData.moment(
        headline: 'GOAL',
        minute: "45+2'",
        score: '2-1',
        playerName: 'Salah',
        suggestedTemplate: CardTemplate.goal,
      );
      final json = data.toJson();
      expect(json['headline'], 'GOAL');

      final restored = CardData.fromJson(json);
      expect(restored, isA<Moment>());
      expect((restored as Moment).minute, "45+2'");
      expect(restored.effectiveTemplate, CardTemplate.goal);
      expect(restored.microStat, "45+2'");
    });

    test('retargeting a moment keeps its data shape', () {
      final data = CardData.moment(headline: 'GOAL', subtext: 'Salah');
      final retargeted = data.adaptToTemplate(CardTemplate.nextUp);
      expect(retargeted, isA<Moment>());
      expect((retargeted as Moment).headline, 'GOAL');
      expect(retargeted.suggestedTemplate, CardTemplate.nextUp);
    });
  });
}
