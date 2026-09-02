import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/primitives.dart';

void main() {
  group('ContentFitResolver', () {
    test('resolves spacious density for light content', () {
      final density = ContentFitResolver.resolve(
        hero: 'Haaland',
        headline: 'Hat-trick hero',
        subtext: 'Great match',
        listItems: 0,
      );
      expect(density, ContentDensity.spacious);
    });

    test('resolves normal density for medium content', () {
      final density = ContentFitResolver.resolve(
        hero: 'Kylian Mbappe Lottin',
        headline: 'Real Madrid seal dramatic comeback against Bayern Munich',
        subtext: 'A thrilling encounter in Madrid sends Los Blancos to the final with sensational late goals.',
        listItems: 2,
      );
      expect(density, ContentDensity.normal);
    });

    test('resolves compact density for heavy content load', () {
      final density = ContentFitResolver.resolve(
        hero: 'Very Long Player Name Super Extra Long Title That Exceeds Normal Limits',
        headline: 'Massive breaking transfer saga confirmed after extensive multi-club negotiations across Europe',
        subtext: 'Long quote explaining in excruciating detail why the contract terms were accepted after weeks of uncertainty and discussions.',
        listItems: 5,
      );
      expect(density, ContentDensity.compact);
    });
  });

  group('CardTypography', () {
    test('hero typography has condensed font and black weight', () {
      expect(CardTypography.hero.fontFamily, 'BarlowCondensed');
      expect(CardTypography.hero.fontWeight, FontWeight.w900);
      expect(CardTypography.hero.fontSize, 96);
    });

    test('headline typography has condensed font and bold weight', () {
      expect(CardTypography.headline.fontFamily, 'BarlowCondensed');
      expect(CardTypography.headline.fontWeight, FontWeight.w700);
      expect(CardTypography.headline.fontSize, 44);
    });

    test('kicker typography has wide tracking', () {
      final kicker = CardTypography.kicker();
      expect(kicker.fontFamily, 'Inter');
      expect(kicker.letterSpacing, greaterThanOrEqualTo(3.0));
      expect(kicker.fontWeight, FontWeight.w700);
    });

    test('body and meta typography scales appropriately', () {
      final body = CardTypography.body();
      final meta = CardTypography.meta();
      expect(body.fontSize, 16);
      expect(meta.fontSize, 12);
      expect(meta.letterSpacing, 0.8);
    });
  });

  group('Broadcast Primitives Widgets', () {
    testWidgets('FadeHairline renders gradient container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FadeHairline(opacity: 0.3, height: 2)),
        ),
      );
      expect(find.byType(FadeHairline), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FadeHairline),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.gradient, isA<LinearGradient>());
    });

    testWidgets('Vignette renders radial gradient overlay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [Vignette(strength: 0.6)])),
        ),
      );
      expect(find.byType(Vignette), findsOneWidget);
    });

    testWidgets('SubjectGlow renders circular radial glow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SubjectGlow(
              color: Colors.amber,
              size: 100,
              child: Text('Subject'),
            ),
          ),
        ),
      );
      expect(find.byType(SubjectGlow), findsOneWidget);
      expect(find.text('Subject'), findsOneWidget);
    });

    testWidgets('BroadcastBackground renders layered structure with child', (
      tester,
    ) async {
      const config = CardConfig(
        colorPair: [Colors.blue, Colors.indigo],
        showScrim: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: BroadcastBackground(
                config: config,
                child: Text('Broadcast Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BroadcastBackground), findsOneWidget);
      expect(find.byType(Vignette), findsOneWidget);
      expect(find.text('Broadcast Content'), findsOneWidget);
    });
  });
}
