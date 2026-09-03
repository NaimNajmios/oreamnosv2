import 'package:equatable/equatable.dart';
import 'package:oreamnos/core/utils/readability_utils.dart';
import 'package:oreamnos/domain/services/source_policy.dart';

/// Attribution for the original source, kept separate from body.
class SourceAttribution extends Equatable {
  final String label;
  final String? url;
  final String? domain;
  final bool isInferred;

  const SourceAttribution({
    required this.label,
    this.url,
    this.domain,
    this.isInferred = false,
  });

  factory SourceAttribution.fromJson(Map<String, dynamic> json) {
    return SourceAttribution(
      label: (json['label'] as String?)?.trim() ?? '',
      url: (json['url'] as String?)?.trim().isEmpty == true
          ? null
          : (json['url'] as String?)?.trim(),
      domain: (json['domain'] as String?)?.trim(),
      isInferred: json['isInferred'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'url': url,
    'domain': domain,
    'isInferred': isInferred,
  };

  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get isEmpty => label.isEmpty && !hasUrl;

  @override
  List<Object?> get props => [label, url, domain, isInferred];
}

/// Result of web scraping, preserving metadata separately from text.
///
/// [siteName] is the portal/outlet name (og:site_name etc.) used as the
/// preferred `source.label` candidate. [url]/[domain] are internal only and
/// must never be displayed as the citation label (see [SourcePolicy]).
class ExtractedArticle extends Equatable {
  final String text;
  final String? pageTitle;
  final String url;
  final String domain;
  final String? description;
  final String? faviconUrl;
  final String? siteName;

  const ExtractedArticle({
    required this.text,
    required this.url,
    required this.domain,
    this.pageTitle,
    this.description,
    this.faviconUrl,
    this.siteName,
  });

  @override
  List<Object?> get props => [
    text,
    pageTitle,
    url,
    domain,
    description,
    faviconUrl,
    siteName,
  ];
}

class CuratedPost extends Equatable {
  final String title;
  final String bodyMarkdown;
  final List<String> hashtags;
  final SourceAttribution source;
  final String rawMarkdown;

  const CuratedPost({
    required this.title,
    required this.bodyMarkdown,
    required this.hashtags,
    required this.source,
    required this.rawMarkdown,
  });

  CuratedPost copyWith({
    String? title,
    String? bodyMarkdown,
    List<String>? hashtags,
    SourceAttribution? source,
  }) {
    final newTitle = title ?? this.title;
    final newBody = bodyMarkdown ?? this.bodyMarkdown;
    final newHashtags = hashtags ?? this.hashtags;
    final newSource = source ?? this.source;

    final buf = StringBuffer();
    if (newTitle.isNotEmpty) {
      buf.writeln(newTitle);
      buf.writeln();
    }
    if (newBody.isNotEmpty) buf.writeln(newBody);
    if (newHashtags.isNotEmpty) {
      if (newBody.isNotEmpty) buf.writeln();
      buf.write(newHashtags.map((h) => '#$h').join('\n'));
    }

    return CuratedPost(
      title: newTitle,
      bodyMarkdown: newBody,
      hashtags: newHashtags,
      source: newSource,
      rawMarkdown: buf.toString().trim(),
    );
  }

  /// Regex to strip emoji (broad unicode ranges).
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{1FA70}-\u{1FAFF}]',
    unicode: true,
  );

  static String _stripEmoji(String s) => s
      .replaceAll(_emojiRegex, '')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .trim();

  static String _normalizeHashtag(String s) {
    var t = s.trim();
    if (t.startsWith('#')) t = t.substring(1);
    t = _stripEmoji(t).replaceAll(RegExp(r'\s+'), '');
    return t;
  }

  static const Set<String> _minorWords = {
    'dan',
    'di',
    'ke',
    'atau',
    'yang',
    'untuk',
    'dari',
    'daripada',
    'dengan',
    'dalam',
    'pada',
    'oleh',
    'itu',
    'ini',
    'telah',
    'akan',
    'adalah',
    'ialah',
    'kepada',
    'serta',
    'atas',
    'bawah',
    'and',
    'or',
    'the',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'a',
    'an',
    'vs',
  };

  static String _toTitleCase(String input) {
    if (input.trim().isEmpty) return input;
    final words = input.trim().split(RegExp(r'\s+'));
    final result = <String>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      // Preserve acronyms (e.g. EPL, UCL, VAR, JDT, FIFA) or words with digits/symbols
      if (word.length > 1 &&
          word == word.toUpperCase() &&
          RegExp(r'^[A-Z0-9]+$').hasMatch(word)) {
        result.add(word);
        continue;
      }

      final lower = word.toLowerCase();
      // First word is always capitalized; minor words in between stay lowercase
      if (i > 0 && _minorWords.contains(lower)) {
        result.add(lower);
      } else {
        if (word.length == 1) {
          result.add(word.toUpperCase());
        } else {
          result.add(
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
          );
        }
      }
    }
    return result.join(' ');
  }

  factory CuratedPost.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['title'] as String?) ?? '';
    final rawBody =
        (json['body'] as String?) ?? (json['content'] as String?) ?? '';
    final rawHashtags = json['hashtags'];
    final rawSource = json['source'];

    String title = _stripEmoji(rawTitle.trim());
    // Title: single line, max 100 chars, converted to Title Case
    title = title.split('\n').first.trim();
    if (title.length > 100) title = title.substring(0, 100).trim();
    title = _toTitleCase(title);

    String body = _stripEmoji(rawBody.trim());
    // Remove any accidental source/hashtag block inside body
    body = body
        .replaceAll(
          RegExp(
            r'\n+\s*(Sumber|Source)\s*[:\-—][^\n]*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    body = body.replaceAll(RegExp(r'(\n\s*#[^\n]*)+$'), '').trim();
    body = _formatBody(body);

    List<String> hashtags = [];
    if (rawHashtags is List) {
      hashtags = rawHashtags
          .map((e) => _normalizeHashtag(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawHashtags is String) {
      hashtags = rawHashtags
          .split(RegExp(r'[,\s]+'))
          .map(_normalizeHashtag)
          .where((e) => e.isNotEmpty)
          .toList();
    }

    SourceAttribution source;
    if (rawSource is Map<String, dynamic>) {
      source = SourceAttribution.fromJson(rawSource);
    } else if (rawSource is String) {
      final s = rawSource.trim();
      source = s.isEmpty
          ? const SourceAttribution(label: '')
          : SourceAttribution(label: _stripEmoji(s));
    } else {
      source = const SourceAttribution(label: '');
    }

    source = _sanitizeSource(source);

    // Build rawMarkdown: title + body + hashtags only (no source inside)
    final buf = StringBuffer();
    if (title.isNotEmpty) {
      buf.writeln(title);
      buf.writeln();
    }
    if (body.isNotEmpty) buf.writeln(body);
    if (hashtags.isNotEmpty) {
      if (body.isNotEmpty) buf.writeln();
      buf.write(hashtags.map((h) => '#$h').join('\n'));
    }
    final rawMarkdown = buf.toString().trim();

    return CuratedPost(
      title: title,
      bodyMarkdown: body,
      hashtags: hashtags,
      source: source,
      rawMarkdown: rawMarkdown,
    );
  }

  static String _formatBody(String body) {
    if (body.isEmpty) return body;
    final canonical = _canonicalizeBody(body);
    // Preserve bullet lists as-is (now paste-safe with •)
    if (canonical.contains(RegExp(r'^\s*•\s', multiLine: true))) {
      return canonical;
    }

    // Delegate to ReadabilityUtils to handle paragraph splitting (max 40 words per paragraph)
    return ReadabilityUtils.splitLongParagraphs(
      canonical.trim(),
      maxWordsPerParagraph: 40,
    );
  }

  /// Canonicalizes body text so display and clipboard agree (WYSIWYG copy).
  /// Normalizes every list marker to paste-safe `•`, strips markdown syntax
  /// that `MarkdownBody` hides visually but clipboard would leak literally,
  /// and collapses 3+ newlines. Idempotent — safe to run on already-clean text.
  static String _canonicalizeBody(String input) {
    var text = input.replaceAll('\r\n', '\n');
    final lines = text.split('\n');
    final out = <String>[];
    for (var line in lines) {
      var l = line.replaceAll(RegExp(r'[ \t]+$'), '');
      // Strip heading / quote markers the renderer hides but paste would leak.
      l = l.replaceAll(RegExp(r'^\s*#{1,6}\s+'), '');
      l = l.replaceAll(RegExp(r'^\s*>\s?'), '');
      // Normalize bullets: - * + > • · ▪ ▫ ‣ ⁃ → •
      l = l.replaceAllMapped(
        RegExp(r'^(\s*)[-*+>•·▪▫‣⁃](\s+)'),
        (m) => '${m.group(1)}•${m.group(2)}',
      );
      // Numbered / lettered list markers → • (prompt mandates • only).
      l = l.replaceAllMapped(
        RegExp(r'^(\s*)\d{1,3}[.)](\s+)'),
        (m) => '${m.group(1)}•${m.group(2)}',
      );
      l = l.replaceAllMapped(
        RegExp(r'^(\s*)[a-z]\)(\s+)'),
        (m) => '${m.group(1)}•${m.group(2)}',
      );
      out.add(l);
    }
    text = out.join('\n');
    // Strip inline markdown the renderer hides but paste would leak.
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAllMapped(RegExp(r'__(.*?)__'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => m.group(1) ?? '');
    text = text.replaceAll(RegExp(r'`+'), '');
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    return text.trim();
  }

  /// Plain-text normalizer for clipboard/share targets with no markdown
  /// engine (WhatsApp, FB, X, Notes). Guarantees bullets survive as `•`.
  static String toPlainText(String input) {
    return _canonicalizeBody(input);
  }

  static SourceAttribution _sanitizeSource(SourceAttribution source) {
    // Central policy: label must be an outlet name from content, never a
    // URL/domain/platform/handle. URL is kept internally (Open/Copy) and
    // Twitter/X links are kept too (internal only) — only the label is
    // hardened here.
    final label = SourcePolicy.sanitizeLabel(source.label);
    String? url = source.url;

    if (label.isEmpty && url == null) {
      return const SourceAttribution(label: '');
    }

    return SourceAttribution(
      label: label,
      url: url,
      domain: source.domain,
      isInferred: source.isInferred,
    );
  }

  /// Fallback when LLM returns plain markdown instead of JSON.
  factory CuratedPost.fromMarkdownFallback(
    String markdown, {
    SourceAttribution? source,
  }) {
    var text = _stripEmoji(markdown.trim());
    if (text.isEmpty) {
      return CuratedPost(
        title: '',
        bodyMarkdown: '',
        hashtags: [],
        source: source ?? const SourceAttribution(label: ''),
        rawMarkdown: '',
      );
    }

    // Extract trailing hashtags
    final hashtagRegex = RegExp(r'(\n\s*#[^\n]*)+$');
    final hashtagBlock = hashtagRegex.firstMatch(text)?.group(0) ?? '';
    final hashtagList = RegExp(r'#([^\s#]+)')
        .allMatches(hashtagBlock)
        .map((m) => _normalizeHashtag(m.group(1)!))
        .where((e) => e.isNotEmpty)
        .toList();
    text = text.replaceAll(hashtagRegex, '').trim();
    text = text.replaceAll(RegExp(r'\n+(#[^\s#]+\s*)+$'), '').trim();

    // Extract source line if present (but keep separate)
    SourceAttribution resolvedSource =
        source ?? const SourceAttribution(label: '');
    final sourceRegex = RegExp(
      r'\n+\s*(Sumber|Source)\s*[:\-—][^\n]*$',
      caseSensitive: false,
    );
    final sourceMatch = sourceRegex.firstMatch(text);
    if (sourceMatch != null) {
      final sourceLine = sourceMatch.group(0)!.trim();
      // Try to extract URL from source line
      final urlRegex = RegExp(r'https?://[^\s]+');
      final urlMatch = urlRegex.firstMatch(sourceLine);
      resolvedSource = SourceAttribution(
        label: _stripEmoji(
          sourceLine
              .replaceAll(urlRegex, '')
              .replaceAll(
                RegExp(r'^(Sumber|Source)\s*[:\-—]\s*', caseSensitive: false),
                '',
              )
              .trim(),
        ),
        url: urlMatch?.group(0),
        domain: urlMatch != null
            ? Uri.tryParse(urlMatch.group(0)!)?.host
            : null,
      );
      text = text.replaceAll(sourceRegex, '').trim();
    }
    resolvedSource = _sanitizeSource(resolvedSource);

    // Title is first line if it looks like heading/bold or first line <100 chars and remaining text is longer
    String title = '';
    String body = text;
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      final first = lines.first
          .trim()
          .replaceAll(RegExp(r'^#+\s*'), '')
          .replaceAll(RegExp(r'^\*\*|\*\*$'), '')
          .trim();
      if (first.isNotEmpty &&
          first.length <= 120 &&
          text.length > first.length + 20) {
        // Heuristic: treat first line as title if next lines exist
        title = _stripEmoji(first);
        if (title.length > 100) title = title.substring(0, 100).trim();
        title = _toTitleCase(title);
        body = lines.skip(1).join('\n').trim().replaceAll(RegExp(r'^\n+'), '');
      }
    }
    body = _formatBody(body);

    final buf = StringBuffer();
    if (title.isNotEmpty) {
      buf.writeln(title);
      buf.writeln();
    }
    if (body.isNotEmpty) buf.writeln(body);
    if (hashtagList.isNotEmpty) {
      if (body.isNotEmpty) buf.writeln();
      buf.write(hashtagList.map((h) => '#$h').join(' '));
    }

    return CuratedPost(
      title: title,
      bodyMarkdown: body,
      hashtags: hashtagList,
      source: resolvedSource,
      rawMarkdown: buf.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': bodyMarkdown,
    'hashtags': hashtags,
    'source': source.toJson(),
    'rawMarkdown': rawMarkdown,
  };

  /// Markdown filtered by toggles: title/hashtags/source.
  /// Source is NOT inside rawMarkdown; when showSource is true, caller should render source card separately.
  /// For copy, we optionally append source url if requested.
  String toMarkdownFiltered({
    bool showTitle = true,
    bool showHashtags = true,
    bool showSource = false,
    bool appendSourceForCopy = false,
  }) {
    final buf = StringBuffer();
    if (showTitle && title.isNotEmpty) {
      buf.writeln(title);
      buf.writeln();
    }
    if (bodyMarkdown.isNotEmpty) buf.writeln(bodyMarkdown);

    // Never emit a URL/domain as the citation text. Only the hardened
    // outlet label is copied; when it is empty the Sumber line is omitted
    // entirely (url stays in the model for Open/Copy buttons only).
    if (appendSourceForCopy && showSource && source.label.trim().isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.write('Sumber: ${source.label.trim()}');
    }

    if (showHashtags && hashtags.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.write(hashtags.map((h) => '#$h').join('\n'));
    }

    return buf.toString().trim();
  }

  /// Paste-safe plain text for clipboard/share targets with no markdown
  /// engine. Same layout as [toMarkdownFiltered] (hashtags newline-per-tag
  /// per user choice B) but re-normalized so `•` bullets and `#tags` survive
  /// paste exactly as displayed. Use for ALL copy/share callers.
  String toPlainTextFiltered({
    bool showTitle = true,
    bool showHashtags = true,
    bool showSource = false,
    bool appendSourceForCopy = false,
  }) {
    final md = toMarkdownFiltered(
      showTitle: showTitle,
      showHashtags: showHashtags,
      showSource: showSource,
      appendSourceForCopy: appendSourceForCopy,
    );
    return toPlainText(md);
  }

  /// For card generator: body only
  String get bodyForCard => bodyMarkdown;

  @override
  List<Object?> get props => [
    title,
    bodyMarkdown,
    hashtags,
    source,
    rawMarkdown,
  ];
}
