import 'package:flutter/material.dart';

/// Colour-matrix helpers for card photo treatments.
abstract final class CardFilters {
  /// Builds a gradient-map style duotone matrix.
  ///
  /// Luminance is mapped linearly from [shadow] to [light] on each RGB channel
  /// while alpha is left untouched — the same operation as Photoshop's
  /// Gradient Map with two stops. Flutter applies `ColorFilter.matrix` in the
  /// 0–1 range, and the offset is the shadow colour's channel value.
  static List<double> duotone(Color shadow, Color light) {
    final sr = shadow.r;
    final sg = shadow.g;
    final sb = shadow.b;
    final lr = light.r;
    final lg = light.g;
    final lb = light.b;

    final dr = lr - sr;
    final dg = lg - sg;
    final db = lb - sb;

    return [
      dr * 0.2126,
      dr * 0.7152,
      dr * 0.0722,
      0,
      sr,
      dg * 0.2126,
      dg * 0.7152,
      dg * 0.0722,
      0,
      sg,
      db * 0.2126,
      db * 0.7152,
      db * 0.0722,
      0,
      sb,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}
