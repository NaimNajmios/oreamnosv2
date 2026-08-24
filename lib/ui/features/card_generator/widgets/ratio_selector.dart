import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

/// Compact ratio selector — 3 primary chips, rest behind "More"
class RatioSelector extends StatefulWidget {
  final CardRatio selected;
  final ValueChanged<CardRatio> onSelect;

  const RatioSelector({super.key, required this.selected, required this.onSelect});

  @override
  State<RatioSelector> createState() => _RatioSelectorState();
}

class _RatioSelectorState extends State<RatioSelector> {
  bool _showMore = false;

  static const _primary = [CardRatio.portrait45, CardRatio.square, CardRatio.story];
  static const _more = [CardRatio.wide, CardRatio.photo34];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primarySelected = _primary.contains(widget.selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('RATIO', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(width: AppSpacing.sm),
            Text(widget.selected.hint, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 11)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final r in _primary)
              AppChip(label: r.label, selected: widget.selected == r, onTap: () => widget.onSelect(r)),
            if (!_showMore && _more.contains(widget.selected))
              for (final r in _more.where((e) => e == widget.selected))
                AppChip(label: r.label, selected: true, onTap: () => widget.onSelect(r)),
            AppChip(
              label: _showMore ? 'Less' : 'More',
              icon: _showMore ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              onTap: () => setState(() => _showMore = !_showMore),
            ),
          ],
        ),
        if (_showMore) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final r in _more)
                if (r != widget.selected || !primarySelected)
                  AppChip(label: r.label, selected: widget.selected == r, onTap: () => widget.onSelect(r)),
            ],
          ),
        ],
      ],
    );
  }
}
