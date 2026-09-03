import 'package:flutter/material.dart';

/// EDIT↔SAVE morphing button (Android `FluidEditButton` parity).
class FluidEditButton extends StatelessWidget {
  const FluidEditButton({
    super.key,
    required this.isEditing,
    required this.onToggle,
  });

  final bool isEditing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: isEditing ? 'Save edits' : 'Edit post',
      onPressed: onToggle,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isEditing ? Icons.check_rounded : Icons.edit_outlined,
          key: ValueKey(isEditing),
          size: 20,
          color: isEditing ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }
}
