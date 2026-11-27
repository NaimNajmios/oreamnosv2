import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/contrast_badge.dart';

void main() {
  testWidgets('shows a low-contrast warning', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContrastBadge(
            foreground: Color(0xFF777777),
            background: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
    expect(find.textContaining('Low contrast'), findsOneWidget);
  });

  testWidgets('shows the ratio when readable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContrastBadge(
            foreground: Colors.white,
            background: Color(0xFF0B0B0F),
          ),
        ),
      ),
    );
    expect(find.textContaining('Contrast'), findsOneWidget);
  });
}
