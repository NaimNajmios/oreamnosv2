import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_state.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/brand_footer.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/crest_badge.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/renderers/headline_quote_canvas.dart';

void main() {
  testWidgets('poster quote card uses one brand mark and typographic quotes', (
    tester,
  ) async {
    final data = CardData.headlineQuote(
      headline: 'Never give up',
      subtext: 'The season is won in the details',
      quoteAuthor: 'Pep Guardiola',
      category: 'QUOTE OF THE DAY',
    ) as HeadlineQuote;

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
              child: HeadlineQuoteCanvas(
                data: data,
                config: const CardConfig(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('“The season is won in the details”'), findsOneWidget);
    expect(find.byType(BrandFooter), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BrandFooter),
        matching: find.byType(CrestBadge),
      ),
      findsOneWidget,
    );
  });
}

class _FakeCardGeneratorViewModel extends CardGeneratorViewModel {
  _FakeCardGeneratorViewModel();

  @override
  CardGeneratorState build() => const CardGeneratorState();
}
