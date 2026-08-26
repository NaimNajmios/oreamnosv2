import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

class InputClearButton extends StatefulWidget {
  const InputClearButton({
    super.key,
    required this.onClear,
    this.label = 'Clear',
    this.confirmLabel = 'Confirm?',
    this.timeout = const Duration(seconds: 3),
  });

  final VoidCallback onClear;
  final String label;
  final String confirmLabel;
  final Duration timeout;

  @override
  State<InputClearButton> createState() => _InputClearButtonState();
}

class _InputClearButtonState extends State<InputClearButton>
    with SingleTickerProviderStateMixin {
  bool _isConfirming = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleClick() {
    if (!_isConfirming) {
      Haptics.selectionClick();
      setState(() => _isConfirming = true);
      _timer?.cancel();
      _timer = Timer(widget.timeout, () {
        if (mounted) setState(() => _isConfirming = false);
      });
    } else {
      _timer?.cancel();
      Haptics.mediumImpact();
      setState(() => _isConfirming = false);
      widget.onClear();
    }
  }

  void reset() {
    if (_isConfirming) {
      _timer?.cancel();
      setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isConfirming
          ? TextButton.icon(
              key: const ValueKey('confirming'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.error.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
              ),
              onPressed: _handleClick,
              icon: const Icon(Icons.warning_amber_rounded, size: 14),
              label: Text(
                widget.confirmLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : TextButton.icon(
              key: const ValueKey('idle'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _handleClick,
              icon: const Icon(Icons.clear_rounded, size: 14),
              label: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
