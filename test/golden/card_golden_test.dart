import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_template.dart';

import '../helpers/card_golden_painter.dart';
import '../helpers/golden_helpers.dart';

void main() {
  const ratios = [('45', 380.0, 475.0), ('story', 380.0, 675.0)];

  for (final template in CardTemplate.all) {
    for (final (ratio, width, height) in ratios) {
      testWidgets('card golden ${template.name}_$ratio', (tester) async {
        await tester.runAsync(() async {
          final image = await renderPainter(
            CardGoldenPainter(
              kicker: template.displayName,
              hero: template.name.toUpperCase(),
              template: template.name,
            ),
            Size(width, height),
          );
          await expectGolden(
            image,
            'test/goldens/card_${template.name}_$ratio.png',
          );
          image.dispose();
        });
      });
    }
  }
}
