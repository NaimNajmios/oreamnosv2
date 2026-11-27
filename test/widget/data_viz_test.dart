import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/form_pills.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/sparkline.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/stat_bar.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/stat_tile.dart';

void main() {
  testWidgets('data-viz primitives render', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatTile(label: 'Goals', value: '12', caption: 'All comps'),
              StatBar(
                label: 'Possession',
                homeValue: '62%',
                awayValue: '38%',
                homeColor: Colors.blue,
                awayColor: Colors.red,
              ),
              FormPills(form: 'WWDWL'),
              SizedBox(width: 100, child: Sparkline(values: [1, 3, 2, 5])),
            ],
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('GOALS'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('W'), findsNWidgets(3));
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
