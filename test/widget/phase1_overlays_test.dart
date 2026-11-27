import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/glass_tile.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/halftone_overlay.dart';

void main() {
  testWidgets('halftone overlay tiles the bundled pattern', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HalftoneOverlay(child: ColoredBox(color: Colors.black)),
        ),
      ),
    );

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(HalftoneOverlay),
        matching: find.byType(DecoratedBox),
      ),
    );
    final image = (box.decoration as BoxDecoration).image!.image as AssetImage;
    expect(image.assetName, 'assets/textures/halftone.png');
  });

  testWidgets('glass tile blurs its backdrop and keeps the child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassTile(
            child: SizedBox(key: Key('tile-child'), width: 40, height: 40),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('tile-child')), findsOneWidget);
    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.filter, isA<ui.ImageFilter>());
  });
}
