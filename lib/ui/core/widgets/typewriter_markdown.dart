import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_typography.dart';

/// Markdown renderer with typewriter streaming animation.
class TypewriterMarkdown extends StatefulWidget {
  final String data;
  final Duration duration;
  final VoidCallback? onComplete;

  const TypewriterMarkdown({
    super.key,
    required this.data,
    this.duration = AppMotion.typewriter,
    this.onComplete,
  });

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  String _displayedText = '';
  Timer? _timer;
  int _currentIndex = 0;
  bool _didInitAnimation = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitAnimation) {
      _didInitAnimation = true;
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer?.cancel();
    _currentIndex = 0;
    _displayedText = '';

    if (widget.data.isEmpty) return;

    final reduceMotion = AppMotion.shouldReduceMotion(context);
    if (reduceMotion) {
      setState(() {
        _displayedText = widget.data;
      });
      widget.onComplete?.call();
      return;
    }

    _timer = Timer.periodic(widget.duration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentIndex < widget.data.length) {
        final step = (widget.data.length - _currentIndex > 100) ? 4 : 2;
        final nextIndex = (_currentIndex + step <= widget.data.length)
            ? _currentIndex + step
            : widget.data.length;

        setState(() {
          _displayedText = widget.data.substring(0, nextIndex);
          _currentIndex = nextIndex;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Replace newlines with double newlines to force markdown paragraph breaks.
    // This prevents MarkdownBody from merging single newlines into a single paragraph.
    final processedText = _displayedText.replaceAll('\n', '\n\n');

    return MarkdownBody(
      data: processedText,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(
          height: 1.65,
          color: theme.colorScheme.onSurface,
        ),
        pPadding: const EdgeInsets.only(bottom: 12),
        h1: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        h2: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        code: AppTypography.mono(
          fontSize: 13,
          color: theme.colorScheme.primary,
        ),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
      ),
    );
  }
}
