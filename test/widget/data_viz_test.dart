import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/data_viz_advanced.dart';
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

  testWidgets('advanced data-viz modules render from manual input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BumpChart(positions: '3,5,2,4'),
              RadarChart(metrics: '0.8,0.6,0.9,0.4,0.7,0.5'),
              XgTimeline(points: '12:0.3,45:0.7,70:0.2'),
              ShotMap(shots: '0.2,0.8,0.4,goal;0.7,0.3,0.1,miss'),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
  });
}
