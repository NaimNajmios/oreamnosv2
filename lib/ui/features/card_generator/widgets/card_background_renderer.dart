import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:oreamnos/domain/models/card_config.dart';

import '../view_models/card_generator_state.dart';

/// Renders the card background including preset gradients, custom images,
/// photo filters, opacity, blur, and positioning.
class CardBackgroundRenderer extends StatelessWidget {
  final CardGeneratorState state;

  const CardBackgroundRenderer({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.backgroundType == BackgroundType.preset &&
        state.presetBackground != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: presetGradient(state.presetBackground!),
        ),
      );
    } else if (state.backgroundImage != null) {
      return buildBackgroundByPosition(state);
    }
    return const SizedBox.shrink();
  }

  static LinearGradient presetGradient(PresetBackground preset) {
    return switch (preset) {
      PresetBackground.stadiumBlur => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF334155)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      PresetBackground.darkMesh => const LinearGradient(
        colors: [Color(0xFF111827), Color(0xFF1F2937)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      PresetBackground.grassTexture => const LinearGradient(
        colors: [Color(0xFF14532D), Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    };
  }

  Widget buildBackgroundByPosition(CardGeneratorState state) {
    final img = wrapWithOpacityAndBlur(
      opacity: state.imageOpacity,
      blur: state.backgroundBlurRadius,
      child: applyPhotoFilter(
        state.photoFilter,
        Image.file(state.backgroundImage!, fit: BoxFit.cover),
      ),
    );

    switch (state.imagePosition) {
      case ImagePosition.splitLeft:
        return Row(
          children: [
            Expanded(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.5,
                maxScale: 4.0,
                child: img,
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        );
      case ImagePosition.splitRight:
        return Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.5,
                maxScale: 4.0,
                child: img,
              ),
            ),
          ],
        );
      case ImagePosition.overlayTop:
        return Column(
          children: [
            SizedBox(
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: img,
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        );
      case ImagePosition.minimal:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 200, height: 200, child: img),
            ),
          ),
        );
      case ImagePosition.cutout:
        return Center(
          child: Padding(padding: const EdgeInsets.all(16), child: img),
        );
      case ImagePosition.magazineBold:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: img),
        );
      case ImagePosition.offsetCard:
        return Align(
          alignment: const Alignment(0.2, -0.2),
          child: FractionallySizedBox(
            widthFactor: 0.9,
            heightFactor: 0.85,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: img,
            ),
          ),
        );
      case ImagePosition.brutalist:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: img,
        );
      case ImagePosition.floatWindow:
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 140, height: 140, child: img),
            ),
          ),
        );
      case ImagePosition.background:
        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.5,
          maxScale: 4.0,
          child: img,
        );
    }
  }

  Widget wrapWithOpacityAndBlur({
    required double opacity,
    required double blur,
    required Widget child,
  }) {
    Widget w = child;
    if (opacity < 0.99) {
      w = Opacity(opacity: opacity, child: w);
    }
    if (blur > 0.1) {
      w = ImageFiltered(
        imageFilter: dart_ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: w,
      );
    }
    return w;
  }

  Widget applyPhotoFilter(PhotoFilter filter, Widget child) {
    switch (filter) {
      case PhotoFilter.vibrant:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.4,
            -0.2,
            -0.2,
            0,
            0,
            -0.2,
            1.4,
            -0.2,
            0,
            0,
            -0.2,
            -0.2,
            1.4,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case PhotoFilter.highContrast:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.5,
            0,
            0,
            0,
            -20,
            0,
            1.5,
            0,
            0,
            -20,
            0,
            0,
            1.5,
            0,
            -20,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case PhotoFilter.blackWhite:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case PhotoFilter.vintage:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.393,
            0.769,
            0.189,
            0,
            0,
            0.349,
            0.686,
            0.168,
            0,
            0,
            0.272,
            0.534,
            0.131,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case PhotoFilter.none:
        return child;
    }
  }
}
