import 'package:equatable/equatable.dart';
import 'package:oreamnos/core/utils/readability_utils.dart';

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
class ExtractedArticle extends Equatable {
  final String text;
  final String? pageTitle;
  final String url;
  final String domain;
  final String? description;
  final String? faviconUrl;

  const ExtractedArticle({
    required this.text,
    required this.url,
    required this.domain,
    this.pageTitle,
    this.description,
    this.faviconUrl,
  });

  @override
  List<Object?> get props => [
    text,
    pageTitle,
    url,
    domain,
    description,
    faviconUrl,
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

  static String _stripEmoji(String s) =>
      s.replaceAll(_emojiRegex, '').replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();

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
    // Preserve bullet lists as-is
    if (body.contains(RegExp(r'^\s*[-•]\s', multiLine: true))) return body;

    // Delegate to ReadabilityUtils to handle paragraph splitting (max 40 words per paragraph)
    return ReadabilityUtils.splitLongParagraphs(
      body.trim(),
      maxWordsPerParagraph: 40,
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

    if (appendSourceForCopy && showSource && !source.isEmpty) {
      buf.writeln();
      buf.writeln();
      String sourceText = source.label;
      if (sourceText.isEmpty &&
          source.domain != null &&
          source.domain!.isNotEmpty) {
        sourceText = source.domain!;
      }
      if (sourceText.isEmpty && source.url != null && source.url!.isNotEmpty) {
        sourceText = source.url!;
      }
      buf.write('Sumber: $sourceText');
    }

    if (showHashtags && hashtags.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.write(hashtags.map((h) => '#$h').join('\n'));
    }

    return buf.toString().trim();
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
