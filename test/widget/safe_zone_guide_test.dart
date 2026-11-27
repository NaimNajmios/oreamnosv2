import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/safe_zone_guide.dart';

void main() {
  testWidgets('safe zone guide paints without blocking input', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 475,
            child: SafeZoneGuide(size: ExportSize.portrait),
          ),
        ),
      ),
    );

    expect(find.byType(SafeZoneGuide), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SafeZoneGuide),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SafeZoneGuide),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
