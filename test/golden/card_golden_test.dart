import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/card_golden_painter.dart';
import '../helpers/golden_helpers.dart';

void main() {
  const cases = [
    ('goal_45', 'Goal', 'GOAL', 380.0, 475.0),
    ('quote_45', 'Quote', 'NEVER GIVE UP', 380.0, 475.0),
    ('top_stats_story', 'Top Stats', '2 - 1', 380.0, 675.0),
  ];

  for (final (name, template, hero, width, height) in cases) {
    testWidgets('card layout golden $name', (tester) async {
      await tester.runAsync(() async {
        final image = await renderPainter(
          CardGoldenPainter(kicker: template, hero: hero, template: template),
          Size(width, height),
        );
        await expectGolden(image, 'test/goldens/card_$name.png');
        image.dispose();
      });
    });
  }
}
