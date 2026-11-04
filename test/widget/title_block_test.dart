import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/core/widgets/curated_post_sections.dart';

void main() {
  testWidgets('TitleBlock can render the title in uppercase', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TitleBlock(title: 'Matchday: JDT wins', uppercase: true),
        ),
      ),
    );
    expect(find.text('MATCHDAY: JDT WINS'), findsOneWidget);
    expect(find.text('Matchday: JDT wins'), findsNothing);
  });

  testWidgets('TitleBlock keeps original case by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TitleBlock(title: 'Matchday: JDT wins')),
      ),
    );
    expect(find.text('Matchday: JDT wins'), findsOneWidget);
  });

  testWidgets('TitleBlock hides when not visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TitleBlock(title: 'Matchday', visible: false, uppercase: true),
        ),
      ),
    );
    expect(find.text('MATCHDAY'), findsNothing);
  });
}
