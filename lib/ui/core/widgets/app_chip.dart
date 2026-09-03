import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Serene pill chip with animated selected states and hairline borders.
/// Optional press-scale + long-press mirror the original `NeoChip` motion.
class AppChip extends StatefulWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.icon,
    this.count,
    this.selectedColor,
    this.selectedTextColor,
    this.pressScale = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final int? count;
  final Color? selectedColor;
  final Color? selectedTextColor;

  /// 0.92 press-scale feedback (Android `NeoChip` parity). Disable where
  /// chips sit inside competing gesture arenas.
  final bool pressScale;

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  double _scale = 1.0;

  void _setScale(double v) {
    if (!widget.pressScale || widget.onTap == null) return;
    if (_scale != v) setState(() => _scale = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = widget.selected
        ? (widget.selectedColor ?? theme.colorScheme.primaryContainer)
        : theme.colorScheme.surface;

    final border = widget.selected
        ? (widget.selectedColor ?? theme.colorScheme.primary)
        : theme.colorScheme.outline;

    final textCol = widget.selected
        ? (widget.selectedTextColor ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap == null
            ? null
            : () {
                Haptics.selectionClick();
                widget.onTap?.call();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                Haptics.lightImpact();
                widget.onLongPress?.call();
              },
        onHighlightChanged: (h) => _setScale(h ? 0.92 : 1.0),
        borderRadius: AppSpacing.borderRadiusXl,
        child: AnimatedScale(
          scale: _scale,
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: widget.selected
                      ? Icon(
                          widget.icon ?? Icons.check_rounded,
                          key: const ValueKey('selected'),
                          size: 16,
                          color: textCol,
                        )
                      : widget.icon != null
                      ? Icon(
                          widget.icon,
                          key: const ValueKey('icon'),
                          size: 16,
                          color: textCol,
                        )
                      : const SizedBox.shrink(key: ValueKey('none')),
                ),
                if (widget.selected || widget.icon != null)
                  const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: theme.textTheme.labelMedium?.copyWith(color: textCol),
                ),
                if (widget.count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: textCol.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                    child: Text(
                      widget.count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
