import 'package:flutter/material.dart';
import 'package:oreamnos/domain/models/card_config.dart';

/// Converts 380dp design units into the logical canvas for any export ratio.
///
/// Renderers are authored against a 380-unit-wide design canvas. The ratio
/// adjustment below is the single source of truth for the "Magic Resize"
/// scaling that used to be duplicated as `CardConfig.aspectRatioScale`.
abstract final class CardScale {
  /// Design width used by the editor stage (`CardStage` max width).
  static const double designWidth = 380;

  /// Square design height — the baseline for all type sizes.
  static const double designHeight = 380;

  static double ratioScale(ExportSize size) {
    return switch (size) {
      ExportSize.story => 1.05,
      ExportSize.wide => 0.88,
      ExportSize.portrait || ExportSize.photo34 || ExportSize.square => 1.0,
    };
  }

  /// Logical canvas size in design units for [size].
  static Size logicalSize(ExportSize size) {
    final ratio = size.width / size.height;
    return Size(designWidth, designWidth / ratio);
  }

  /// Scales a design-unit font size for [size] and the user's headline scale.
  static double font(
    double designFontSize, {
    required ExportSize size,
    double userScale = 1.0,
  }) {
    return designFontSize * ratioScale(size) * userScale.clamp(0.5, 2.5);
  }

  /// Scales a design-unit spacing value for [size].
  static double space(double designUnits, {required ExportSize size}) {
    return designUnits * ratioScale(size);
  }
}
