import 'package:flutter/material.dart' hide CardTheme;
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/card_theme.dart';
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
  });
}
