enum ContentDensity { spacious, normal, compact }

/// Calculates content volume and recommends a rendering density
/// so elements gracefully scale down or drop secondary details rather than overflow.
class ContentFitResolver {
  const ContentFitResolver._();

  /// Measures total content load and selects rendering density.
  static ContentDensity resolve({
    String hero = '',
    String headline = '',
    String subtext = '',
    int listItems = 0,
  }) {
    final load =
        hero.length +
        (headline.length * 0.8) +
        (subtext.length * 0.6) +
        (listItems * 35);

    if (load > 260) return ContentDensity.compact;
    if (load > 150) return ContentDensity.normal;
    return ContentDensity.spacious;
  }
}
