import 'package:flutter/material.dart';

import '../../../../../config/theme/card_type.dart';

/// Two-sided comparison bar with tabular values.
class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.homeValue,
    required this.awayValue,
    required this.homeColor,
    required this.awayColor,
  });

  final String label;
  final String homeValue;
  final String awayValue;
  final Color homeColor;
  final Color awayColor;

  static double parse(String raw) =>
      double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 50.0;

  @override
  Widget build(BuildContext context) {
    final home = parse(homeValue);
    final away = parse(awayValue);
    final total = home + away > 0 ? home + away : 100.0;
    final ratio = (home / total).clamp(0.1, 0.9);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              homeValue,
              style: CardType.numeric(
                CardType.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: homeColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: CardType.label.copyWith(
                  fontSize: 10,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              awayValue,
              style: CardType.numeric(
                CardType.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: awayColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: (ratio * 100).toInt(),
                child: Container(height: 6, color: homeColor),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: ((1 - ratio) * 100).toInt(),
                child: Container(height: 6, color: awayColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
