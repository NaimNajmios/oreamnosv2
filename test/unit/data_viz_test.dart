import 'package:flutter/material.dart' hide CardTheme;
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/card_theme.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/data_viz_advanced.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/form_pills.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/primitives/stat_bar.dart';

void main() {
  group('data-viz primitives', () {
    test('StatBar parses values with units', () {
      expect(StatBar.parse('62%'), 62);
      expect(StatBar.parse('1.5'), 1.5);
      expect(StatBar.parse('n/a'), 50);
    });

    test('FormPills maps results to status colours', () {
      expect(FormPills.colorFor('W'), CardTheme.successColor);
      expect(FormPills.colorFor('D'), CardTheme.warningColor);
      expect(FormPills.colorFor('L'), CardTheme.alertColor);
      expect(FormPills.colorFor('?'), Colors.white54);
    });

    test('advanced modules parse compact manual input', () {
      expect(DataVizInput.integers('3, 5; 2'), [3, 5, 2]);
      expect(DataVizInput.decimals('0.8,1.4,-0.2'), [0.8, 1.0, 0.0]);
      expect(DataVizInput.xgPoints('12:0.3,45:0.7'), [0.3, 0.7]);
      final shots = DataVizInput.shots('0.2,0.8,0.4,goal;0.7,0.3,0.1,miss');
      expect(shots.length, 2);
      expect(shots.first.xg, 0.4);
    });
  });
}
