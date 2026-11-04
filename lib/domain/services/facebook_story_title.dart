/// Extracts the short Story title from a post caption.
abstract final class FacebookStoryTitle {
  static const int maxLength = 100;

  static String extract({required String text, String? headline}) {
    final cleanHeadline = _clean(headline ?? '');
    if (cleanHeadline.isNotEmpty) return _truncate(cleanHeadline);
    for (final line in text.split('\n')) {
      final clean = _clean(line);
      if (clean.isNotEmpty) return _truncate(clean);
    }
    return '';
  }

  static String _clean(String input) {
    var value = input.trim();
    // Markdown images → remove entirely; links → keep the label.
    value = value.replaceAllMapped(RegExp(r'!\[[^\]]*\]\([^)]*\)'), (_) => '');
    value = value.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );
    // URLs and trailing hashtags (before stripping markdown markers).
    value = value.replaceAll(RegExp(r'https?://\S+'), '');
    value = value.replaceAll(RegExp(r'#[\w\u0600-\u06FF]+'), '');
    // Bold/italic/code markers and leading list/bullet characters.
    value = value.replaceAll(RegExp(r'[*_`~#>]+'), '');
    value = value.replaceFirst(RegExp(r'^[-•\s]+'), '');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Trim decorative punctuation at the edges.
    value = value.replaceFirst(RegExp(r'^[\s\-–—:;,.!?]+'), '');
    value = value.replaceFirst(RegExp(r'[\s\-–—:;,]+$'), '');
    return value.trim();
  }

  static String _truncate(String value) {
    if (value.length <= maxLength) return value;
    final cut = value.substring(0, maxLength);
    final lastSpace = cut.lastIndexOf(' ');
    final base = lastSpace > maxLength ~/ 2 ? cut.substring(0, lastSpace) : cut;
    return '${base.trimRight()}…';
  }
}
