/// Kickoff motif tokens derived from `icon/icon.svg` (512 viewBox).
///
/// Geometry: black disc r248, 18 orbit dots r14 on orbit r170,
/// center ring r56 stroke12, core dot r10. Ratios below are fractions
/// of the rendered square size so any [KickoffMark] scales exactly.
abstract final class AppKickoff {
  /// Number of dots on the orbit ring (matches the SVG: 18).
  static const int orbitCount = 18;

  /// Orbit radius as fraction of size (170 / 512).
  static const double orbitRadiusFactor = 170 / 512;

  /// Orbit dot radius as fraction of size (14 / 512).
  static const double dotRadiusFactor = 14 / 512;

  /// Center ring radius as fraction of size (56 / 512).
  static const double ringRadiusFactor = 56 / 512;

  /// Center ring stroke width as fraction of size (12 / 512).
  static const double ringStrokeFactor = 12 / 512;

  /// Core dot radius as fraction of size (10 / 512).
  static const double coreRadiusFactor = 10 / 512;

  /// Disc radius as fraction of size (248 / 512).
  static const double discRadiusFactor = 248 / 512;

  /// Maps a 0..1 progress value to a highlighted orbit-dot index.
  /// Returns -1 when progress is null (no accent dot).
  static int accentDotIndex(double? progress, {int count = orbitCount}) {
    if (progress == null || progress.isNaN) return -1;
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return -1;
    if (clamped >= 1) return count - 1;
    return (clamped * count).floor().clamp(0, count - 1);
  }
}
