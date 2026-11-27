import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/giant_text_behind.dart';

void main() {
  testWidgets('renders outlined giant text behind the cutout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: GiantTextBehind(
              text: 'SALAH',
              child: ColoredBox(key: Key('cutout'), color: Colors.blue),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('SALAH'));
    final style = text.style!;
    expect(style.foreground, isNotNull);
    expect(style.foreground!.style, PaintingStyle.stroke);
    expect(find.byKey(const Key('cutout')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('SALAH'),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );

    final stack = tester.widget<Stack>(
      find.ancestor(
        of: find.byKey(const Key('cutout')),
        matching: find.byType(Stack),
      ),
    );
    expect(stack.children.length, 2);
  });
}
