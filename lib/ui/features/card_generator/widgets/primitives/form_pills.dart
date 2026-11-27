import 'package:flutter/material.dart' hide CardTheme;

import '../../../../../config/theme/card_theme.dart';
import '../../../../../config/theme/card_type.dart';

/// W/D/L form pills derived from a compact string such as "WWDWL".
class FormPills extends StatelessWidget {
  const FormPills({super.key, required this.form, this.size = 20});

  final String form;
  final double size;

  static Color colorFor(String result) => switch (result.toUpperCase()) {
    'W' => CardTheme.successColor,
    'D' => CardTheme.warningColor,
    'L' => CardTheme.alertColor,
    _ => Colors.white54,
  };

  @override
  Widget build(BuildContext context) {
    final results = form
        .toUpperCase()
        .split('')
        .where((c) => 'WDL'.contains(c))
        .take(10)
        .toList();
    if (results.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final result in results) ...[
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorFor(result).withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: colorFor(result), width: 1),
            ),
            child: Text(
              result,
              style: CardType.label.copyWith(
                fontSize: size * 0.5,
                fontWeight: FontWeight.w800,
                color: colorFor(result),
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }
}
