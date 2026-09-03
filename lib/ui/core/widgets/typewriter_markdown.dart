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

  /// Normalizes markdown for display: collapses 3+ newlines, trims line
  /// trailing spaces, and maps paste-safe `•` bullets to `-` so
  /// `MarkdownBody` renders them as a tight native list instead of
  /// double-spaced paragraphs. Single `\n` between list items stays tight;
  /// `\n\n` between paragraphs stays airy.
  static String normalizeForDisplay(String input) {
    var text = input.replaceAll('\r\n', '\n');
    text = text.replaceAll(RegExp(r'[ \t]+$'), '');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    final lines = text.split('\n');
    final out = <String>[];
    for (final line in lines) {
      final m = RegExp(r'^(\s*)[•·▪▫‣⁃](\s+)').firstMatch(line);
      if (m != null) {
        out.add('${m.group(1)}- ${line.substring(m.end).trimLeft()}');
      } else {
        out.add(line);
      }
    }
    return out.join('\n');
  }
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

    final processedText = TypewriterMarkdown.normalizeForDisplay(
      _displayedText,
    );

    return MarkdownBody(
      data: processedText,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(
          height: 1.65,
          color: theme.colorScheme.onSurface,
        ),
        pPadding: const EdgeInsets.only(bottom: 12),
        listBullet: theme.textTheme.bodyMedium?.copyWith(
          height: 1.65,
          color: theme.colorScheme.onSurface,
        ),
        listBulletPadding: const EdgeInsets.only(right: 8),
        listIndent: 20,
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
