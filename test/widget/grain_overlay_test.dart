import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/grain_overlay.dart';

void main() {
  testWidgets('grain overlay tiles the bundled texture', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GrainOverlay(child: ColoredBox(color: Colors.black)),
        ),
      ),
    );

    expect(find.byType(GrainOverlay), findsOneWidget);
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(GrainOverlay),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = box.decoration as BoxDecoration;
    final decorationImage = decoration.image!;
    final image = decorationImage.image as AssetImage;
    expect(image.assetName, 'assets/textures/grain.png');
  });

  testWidgets('grain overlay sits inside the export boundary', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: RepaintBoundary(
                key: key,
                child: const GrainOverlay(
                  child: ColoredBox(color: Color(0xFF101820)),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(of: find.byKey(key), matching: find.byType(GrainOverlay)),
      findsOneWidget,
    );
  });
}
