import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

class RatioSelector extends StatelessWidget {
  final CardRatio selected;
  final ValueChanged<CardRatio> onSelect;

  const RatioSelector({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RATIO',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CardRatio.values.map((r) {
              final isSel = r == selected;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Column(
                  children: [
                    AppChip(
                      label: r.label,
                      selected: isSel,
                      onTap: () => onSelect(r),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.hint,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: isSel ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
