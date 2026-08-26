/// Minimal port of Android `FootballOcrParser.formatForPrompt` (project_context 22471).
///
/// Normalizes raw MLKit text before it enters LLM prompts:
/// - Collapses intra-paragraph whitespace while preserving paragraph breaks (`\n\n`).
/// - Normalizes scores like `2 - 1` → `2-1`, `2 : 1` → `2-1`.
/// - Tidies fixture separators and table pipes.
/// - Trims and dedupes empty lines.
class FootballOcrParser {
  static String formatForPrompt(String rawText, {bool addHeader = false}) {
    if (rawText.trim().isEmpty) return '';
    var text = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Normalize scores: "2 - 1", "2 : 1", "2 :1" → "2-1"
    text = text.replaceAllMapped(
      RegExp(r'(\d)\s*[-:]\s*(\d)'),
      (m) => '${m.group(1)}-${m.group(2)}',
    );

    // Normalize fixture "vs" / "v." → "vs"
    text = text.replaceAll(RegExp(r'\b[vV]\.\s*\b'), 'vs ');
    text = text.replaceAll(RegExp(r'\bVS\b'), 'vs');

    // Collapse table pipes with spaces: "Team | P | W" → "Team | P | W" (normalize spaces around |)
    text = text.replaceAllMapped(RegExp(r'\s*\|\s*'), (m) => ' | ');

    if (addHeader) {
      final lines = text.split('\n');
      final out = <String>['[Extracted from screenshot]', '---'];
      for (final line in lines) {
        final t = line.trim();
        if (t.isEmpty) continue;
        if (RegExp(r'\d\s*-\s*\d').hasMatch(t)) {
          out.add('MATCH RESULT: $t');
          continue;
        }
        final label = _detectStatLabel(t);
        if (label != null) {
          out.add('$label: ${_extractNum(t)}');
        } else {
          out.add(t);
        }
      }
      return out.join('\n');
    }

    // Paragraph handling: split on blank lines, clean each, rejoin
    final paras = text.split(RegExp(r'\n\s*\n'));
    final cleaned = paras
        .map((p) {
          // Collapse spaces/tabs, but keep single spaces
          var c = p.replaceAll(RegExp(r'[ \t]+'), ' ');
          // Replace single newlines with space
          c = c.replaceAll(RegExp(r'\n\s*'), ' ');
          return c.trim();
        })
        .where((p) => p.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.join('\n\n').trim();
  }

  static String? _detectStatLabel(String line) {
    final l = line.toLowerCase();
    if (l.contains('goal')) return 'GOALS';
    if (l.contains('assist')) return 'ASSISTS';
    if (l.contains('rating')) return 'RATING';
    if (l.contains('pass') && l.contains('%')) return 'PASS ACCURACY';
    if (l.contains('tackle')) return 'TACKLES';
    if (l.contains('save')) return 'SAVES';
    if (l.contains('yellow')) return 'YELLOW CARDS';
    if (l.contains('red')) return 'RED CARDS';
    return null;
  }

  static String _extractNum(String line) {
    final m = RegExp(r'\d+(\.\d+)?%?').firstMatch(line);
    return m?.group(0) ?? line;
  }
}
