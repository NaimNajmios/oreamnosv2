import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copy button with animated feedback.
/// Shows a checkmark briefly after copying.
class NeoCopyButton extends StatefulWidget {
  const NeoCopyButton({
    super.key,
    required this.textToCopy,
    this.size = 20,
  });

  final String textToCopy;
  final double size;

  @override
  State<NeoCopyButton> createState() => _NeoCopyButtonState();
}

class _NeoCopyButtonState extends State<NeoCopyButton> {
  bool _copied = false;

  Future<void> _onCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: _onCopy,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? Icon(
                Icons.check,
                key: const ValueKey('check'),
                size: widget.size,
                color: Colors.green,
              )
            : Icon(
                Icons.copy,
                key: const ValueKey('copy'),
                size: widget.size,
                color: theme.colorScheme.onSurface,
              ),
      ),
      tooltip: _copied ? 'Copied!' : 'Copy',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
