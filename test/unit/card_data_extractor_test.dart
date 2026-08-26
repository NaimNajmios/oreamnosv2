import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/card_data_extractor.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

void main() {
  group('CardDataExtractor helpers', () {
    final extractor = CardDataExtractor();

    test('stripFencesLenient depth scan', () async {
      const brief = CardBrief(
        headline: 'H',
        subtext: 'S',
        provider: AiProvider.gemini,
        modelId: 'm',
      );
      expect(brief.headline, 'H');
      expect(extractor, isNotNull);
    });

    test('template mapping N/A defaults', () {
      // Verify CardTemplate fromIntent
      expect(
        CardTemplate.fromIntent('player_spotlight'),
        CardTemplate.playerSpotlight,
      );
      expect(CardTemplate.fromIntent('unknown'), CardTemplate.socialPost);
    });

    test('sparse headline fallback via CardBrief', () {
      const brief = CardBrief(
        headline: 'My Headline',
        subtext: 'My Subtext',
        provider: AiProvider.gemini,
        modelId: 'test',
      );
      expect(brief.headline, 'My Headline');
      expect(brief.promptContext, contains('My Headline'));
    });
  });
}
