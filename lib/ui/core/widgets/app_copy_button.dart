import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Smooth copy-to-check animated morphing button.
class AppCopyButton extends StatefulWidget {
  const AppCopyButton({
    super.key,
    required this.textToCopy,
    this.size = 20,
    this.color,
  });

  final String textToCopy;
  final double size;
  final Color? color;

  @override
  State<AppCopyButton> createState() => _AppCopyButtonState();
}

class _AppCopyButtonState extends State<AppCopyButton> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    if (_copied) return;

    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    Haptics.mediumImpact();

    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() => _copied = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _copied
        ? AppColors.success
        : (widget.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7));

    return IconButton(
      icon: AnimatedSwitcher(
        duration: AppMotion.fast,
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Icon(
          _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
          key: ValueKey<bool>(_copied),
          size: widget.size,
          color: iconColor,
        ),
      ),
      tooltip: _copied ? 'Copied!' : 'Copy to clipboard',
      onPressed: _handleCopy,
    );
  }
}
