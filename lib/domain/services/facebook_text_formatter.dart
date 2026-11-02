/// Markdown → plain-text conversion for Facebook publishing.
///
/// Generated posts render through `TypewriterMarkdown`, so `**bold**`,
/// `_underscore emphasis_` and `[links](…)` would leak into the raw feed as
/// literal characters. This strips the syntax while keeping the content:
/// hashtags survive, and a `#` only counts as a heading marker at line
/// start followed by a space — never inside `#hashtag`.
abstract final class FacebookTextFormatter {
  static String toPlainText(String markdown) {
    var text = markdown;

    // Links: [label](url) → "label (url)" — the URL must survive because
    // Facebook renders raw URLs as the clickable preview.
    text = text.replaceAllMapped(RegExp(r'\[([^\]\n]*)\]\(([^)\s]+)\)'), (m) {
      final label = m.group(1)?.trim() ?? '';
      final url = m.group(2)?.trim() ?? '';
      if (label.isEmpty || label == url) return url;
      return '$label ($url)';
    });

    // Headings: `# Title` → "Title". Anchored to line start and requires a
    // space after the hashes, so `#hashtag` at line start is untouched.
    text = text.replaceAllMapped(
      RegExp(r'^[ ]{0,3}#{1,6}[ \t]+(.*)$', multiLine: true),
      (m) => m.group(1) ?? '',
    );

    // Bold then italic. Asterisks pair greedily but never cross lines; a
    // lone `*` used as a bullet stays (handled as a list marker below).
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*\n]+)\*\*'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'\*([^*\n]+)\*'),
      (m) => m.group(1) ?? '',
    );
    // Inline code and strikethrough.
    text = text.replaceAllMapped(RegExp(r'`([^`\n]+)`'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'~~([^~\n]+)~~'), (m) => m.group(1)!);

    // Underscore emphasis `_x_` only across word boundaries (start/space or
    // opening bracket before, end/punctuation after) so snake_case words
    // and inside-hashtag underscores survive untouched.
    text = text.replaceAllMapped(
      RegExp(r'(?<=^|[\s(\[])_([^_\n]+)_(?=$|[ \t.,!?;:)\]])', multiLine: true),
      (m) => m.group(1) ?? '',
    );

    // Blockquote markers, horizontal rules, and list bullets.
    text = text.replaceAllMapped(
      RegExp(r'^[ ]{0,3}>\s?', multiLine: true),
      (_) => '',
    );
    text = text.replaceAll(
      RegExp(r'^[ ]{0,3}(-{3,}|\*{3,}|_{3,})[ \t]*$', multiLine: true),
      '',
    );
    text = text.replaceAllMapped(
      RegExp(r'^[ ]{0,3}[*+-][ \t]+', multiLine: true),
      (_) => '',
    );

    // Blank-line runs collapse to one empty line; all lines trimmed.
    text = text.replaceAll(RegExp(r'^[ ]+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}
