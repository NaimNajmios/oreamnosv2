import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'grain_overlay.dart';

/// Fragment-shader grain with a tiled PNG fallback while the program loads
/// or if the GPU backend does not support it.
class ShaderGrainOverlay extends StatefulWidget {
  const ShaderGrainOverlay({
    super.key,
    required this.child,
    this.strength = 0.35,
  });

  final Widget child;
  final double strength;

  @override
  State<ShaderGrainOverlay> createState() => _ShaderGrainOverlayState();
}

class _ShaderGrainOverlayState extends State<ShaderGrainOverlay> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    ui.FragmentProgram.fromAsset('shaders/grain.frag')
        .then((program) {
          if (mounted) setState(() => _program = program);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;
    if (program == null) {
      return GrainOverlay(strength: widget.strength, child: widget.child);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ShaderPainter(
                program: program,
                strength: widget.strength,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShaderPainter extends CustomPainter {
  const _ShaderPainter({required this.program, required this.strength});

  final ui.FragmentProgram program;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, 7.0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..color = Color.fromRGBO(255, 255, 255, strength),
    );
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter old) =>
      old.program != program || old.strength != strength;
}
