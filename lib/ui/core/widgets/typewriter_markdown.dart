import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TypewriterMarkdown extends StatefulWidget {
  const TypewriterMarkdown({
    super.key,
    required this.data,
    this.duration = const Duration(milliseconds: 15),
  });

  final String data;
  final Duration duration; // duration per character

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration * widget.data.length,
    );
    
    _charCount = StepTween(begin: 0, end: widget.data.length).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void didUpdateWidget(TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.duration = widget.duration * widget.data.length;
      _charCount = StepTween(begin: 0, end: widget.data.length).animate(_controller)
        ..addListener(() {
          setState(() {});
        });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.data.substring(0, _charCount.value);
    
    return MarkdownBody(
      data: visibleText,
      selectable: _controller.isCompleted, // only selectable when finished to avoid focus issues
    );
  }
}

