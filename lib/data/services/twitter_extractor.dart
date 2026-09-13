import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/core/utils/url_detector.dart';
import 'package:oreamnos/domain/services/source_policy.dart';

class TwitterExtractor {
  static final RegExp _xUrlPattern = RegExp(
    r'(?:x\.com|twitter\.com|mobile\.twitter\.com|m\.twitter\.com|vxtwitter\.com|fxtwitter\.com|fixupx\.com)/(?:(\w+)/)?(?:i/web/|i/)?status/(\d+)',
    caseSensitive: false,
  );

  /// Returns true if the URL is an X/Twitter status link
  static bool isTwitterUrl(String text) {
    return UrlDetector.classifyUrl(text) == UrlType.twitterStatus;
  }

  /// Extracts tweet text from an X/Twitter URL using fxtwitter API
  static Future<TweetContent?> extractViaFxTwitter(String url) async {
    return _extractFromApi(url, 'https://api.fxtwitter.com');
  }

  /// Extracts tweet text from an X/Twitter URL using vxtwitter API (fallback)
  static Future<TweetContent?> extractViaVxTwitter(String url) async {
    return _extractFromApi(url, 'https://api.vxtwitter.com');
  }

  static Future<TweetContent?> _extractFromApi(
    String url,
    String baseUrl,
  ) async {
    final match = _xUrlPattern.firstMatch(url);
    if (match == null) return null;

    final username = match.group(1) ?? 'i';
    final tweetId = match.group(2)!;

    try {
      final apiUrl = '$baseUrl/$username/status/$tweetId';
      final apiClient = getIt<ApiClient>();

      final response = await apiClient.get<Map<String, dynamic>>(
        apiUrl,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode != 200) {
        debugPrint('Twitter API error ($baseUrl): ${response.statusCode}');
        return null;
      }

      final data = response.data;
      if (data == null) return null;

      if (data['code'] != 200) {
        debugPrint(
          'Twitter API returned non-200 code ($baseUrl): ${data['code']}',
        );
        return null;
      }

      final tweet = data['tweet'] as Map<String, dynamic>?;
      if (tweet == null) return null;

      final text = tweet['text'] as String? ?? '';
      final author = tweet['author'] as Map<String, dynamic>?;
      final authorName = author?['name'] as String? ?? '';
      final authorHandle = author?['screen_name'] as String? ?? '';
      final metrics = tweet['metrics'] as Map<String, dynamic>?;

      // Extract card attachment details (e.g. summary_large_image, summary)
      final card = tweet['card'] as Map<String, dynamic>?;
      final cardUrl = card?['url'] as String?;
      final cardTitle = card?['title'] as String?;
      final cardDescription = card?['description'] as String?;
      final cardDomain = card?['domain'] as String?;

      // Extract X Article details
      final article = tweet['article'] as Map<String, dynamic>?;
      final articleTitle = article?['title'] as String?;
      final articleContent = (article?['content'] is Map)
          ? (article!['content']['text'] as String? ??
                article['preview_text'] as String?)
          : article?['preview_text'] as String?;

      // Extract expanded destination URLs from raw_text facets
      final expandedUrls = <String>[];
      final rawTextObj = tweet['raw_text'] as Map<String, dynamic>?;
      final facets = rawTextObj?['facets'] as List<dynamic>?;
      if (facets != null) {
        for (final facet in facets) {
          if (facet is Map && facet['type'] == 'url') {
            final replacement = facet['replacement'] as String?;
            if (replacement != null && replacement.isNotEmpty) {
              expandedUrls.add(replacement);
            }
          }
        }
      }

      // Extract quoted tweet
      String? quoteText;
      String? quoteAuthor;
      final quote = tweet['quote'] as Map<String, dynamic>?;
      if (quote != null) {
        quoteText = quote['text'] as String?;
        final qAuthor = quote['author'] as Map<String, dynamic>?;
        quoteAuthor =
            qAuthor?['name'] as String? ?? qAuthor?['screen_name'] as String?;
      }

      return TweetContent(
        text: text,
        authorName: authorName,
        authorHandle: '@$authorHandle',
        candidateOutlet: SourcePolicy.extractOutletFromTweet(text),
        likes: metrics?['likes'] as int? ?? 0,
        retweets: metrics?['retweets'] as int? ?? 0,
        replies: metrics?['replies'] as int? ?? 0,
        views: metrics?['views'] as int? ?? 0,
        createdAt: tweet['created_at'] as String? ?? '',
        sourceUrl: url,
        cardUrl: cardUrl,
        cardTitle: cardTitle,
        cardDescription: cardDescription,
        cardDomain: cardDomain,
        articleTitle: articleTitle,
        articleContent: articleContent,
        quoteText: quoteText,
        quoteAuthor: quoteAuthor,
        expandedUrls: expandedUrls,
      );
    } catch (e) {
      debugPrint('TwitterExtractor error ($baseUrl): $e');
      return null;
    }
  }

  /// Extracts external article URLs found inside the tweet, attached card, or facets.
  ///
  /// Ignores internal X/Twitter status/profile links while preserving t.co
  /// shortlinks (which may redirect to external articles) and external web domains.
  static List<String> extractArticleUrls(
    String text, {
    String? cardUrl,
    List<String>? expandedUrls,
  }) {
    final candidateUrls = <String>[];
    if (cardUrl != null && cardUrl.trim().isNotEmpty) {
      candidateUrls.add(cardUrl.trim());
    }
    if (expandedUrls != null) {
      for (final eu in expandedUrls) {
        if (eu.trim().isNotEmpty) candidateUrls.add(eu.trim());
      }
    }

    if (text.isNotEmpty) {
      final matches = RegExp(
        r'https?://[^\s<>"]+',
        caseSensitive: false,
      ).allMatches(text);
      for (final m in matches) {
        var u = m.group(0)!;
        while (u.isNotEmpty &&
            (u.endsWith('.') ||
                u.endsWith(',') ||
                u.endsWith(')') ||
                u.endsWith(']') ||
                u.endsWith('!') ||
                u.endsWith('?'))) {
          u = u.substring(0, u.length - 1);
        }
        candidateUrls.add(u);
      }
    }

    final validUrls = <String>[];
    final seen = <String>{};

    for (final u in candidateUrls) {
      final uri = Uri.tryParse(u);
      if (uri == null || !uri.hasScheme) continue;
      final host = uri.host.toLowerCase();
      // Skip direct twitter/x status or media URLs
      if ((host == 'twitter.com' ||
              host == 'www.twitter.com' ||
              host == 'x.com' ||
              host == 'www.x.com' ||
              host == 'mobile.twitter.com') &&
          (uri.path.contains('/status/') || uri.path.contains('/i/'))) {
        continue;
      }
      if (seen.add(u)) {
        validUrls.add(u);
      }
    }
    return validUrls;
  }

  /// Formats tweet content into a structured block for the AI prompt.
  ///
  /// The handle/URL are metadata only and must NEVER be used as
  /// `source.label`. The label must come from POST CONTENT (see
  /// [TweetContent.candidateOutlet]) formatted as
  /// "[Outlet] via [Author Display Name]".
  static String formatForAiPrompt(
    TweetContent tweet, {
    String? linkedArticleContent,
    String? linkedArticleUrl,
  }) {
    final sb = StringBuffer();
    sb.writeln('TYPE: social_post');
    sb.writeln('AUTHOR_DISPLAY_NAME: ${tweet.authorDisplayName}');
    sb.writeln(
      'AUTHOR_HANDLE (metadata only, never use as source): '
      '${tweet.authorHandle}',
    );
    sb.writeln('DATE: ${tweet.createdAt}');
    sb.writeln('');
    sb.writeln('POST CONTENT:');
    sb.writeln(tweet.text);
    sb.writeln('');
    sb.writeln(
      'CANDIDATE_OUTLET (heuristic, may be empty): '
      '${tweet.candidateOutlet ?? ''}',
    );
    sb.writeln(
      'SOURCE RULE: Derive source.label ONLY from POST CONTENT / '
      'CANDIDATE_OUTLET. Never use a URL, domain, platform name '
      '(X/Twitter/x.com) or handle-alone.',
    );

    if (tweet.cardTitle != null || tweet.cardDescription != null) {
      sb.writeln('');
      sb.writeln('--- ATTACHED CARD / LINK PREVIEW (from post) ---');
      if (tweet.cardTitle != null && tweet.cardTitle!.isNotEmpty) {
        sb.writeln('CARD TITLE: ${tweet.cardTitle}');
      }
      if (tweet.cardDomain != null && tweet.cardDomain!.isNotEmpty) {
        sb.writeln('CARD DOMAIN: ${tweet.cardDomain}');
      }
      if (tweet.cardUrl != null && tweet.cardUrl!.isNotEmpty) {
        sb.writeln('CARD URL: ${tweet.cardUrl}');
      }
      if (tweet.cardDescription != null && tweet.cardDescription!.isNotEmpty) {
        sb.writeln('CARD DESCRIPTION: ${tweet.cardDescription}');
      }
    }

    if (tweet.articleTitle != null || tweet.articleContent != null) {
      sb.writeln('');
      sb.writeln('--- ATTACHED ARTICLE ---');
      if (tweet.articleTitle != null) {
        sb.writeln('ARTICLE TITLE: ${tweet.articleTitle}');
      }
      if (tweet.articleContent != null) {
        sb.writeln('ARTICLE TEXT: ${tweet.articleContent}');
      }
    }

    if (tweet.quoteText != null && tweet.quoteText!.isNotEmpty) {
      sb.writeln('');
      sb.writeln('--- QUOTED POST (${tweet.quoteAuthor ?? 'Quoted'}) ---');
      sb.writeln(tweet.quoteText);
    }

    if (linkedArticleContent != null &&
        linkedArticleContent.trim().isNotEmpty) {
      sb.writeln('');
      sb.writeln('--- LINKED ARTICLE CONTENT (from link in post) ---');
      if (linkedArticleUrl != null && linkedArticleUrl.isNotEmpty) {
        sb.writeln('ARTICLE_URL: $linkedArticleUrl');
      }
      sb.writeln('ARTICLE_TEXT:');
      sb.writeln(linkedArticleContent.trim());
    }

    return sb.toString();
  }
}

class TweetContent {
  final String text;
  final String authorName;
  final String authorHandle;
  final int likes;
  final int retweets;
  final int replies;
  final int views;
  final String createdAt;
  final String sourceUrl;
  final String? candidateOutlet;
  final String? cardUrl;
  final String? cardTitle;
  final String? cardDescription;
  final String? cardDomain;
  final String? articleTitle;
  final String? articleContent;
  final String? quoteText;
  final String? quoteAuthor;
  final List<String> expandedUrls;

  TweetContent({
    required this.text,
    required this.authorName,
    required this.authorHandle,
    this.likes = 0,
    this.retweets = 0,
    this.replies = 0,
    this.views = 0,
    this.createdAt = '',
    this.sourceUrl = '',
    this.candidateOutlet,
    this.cardUrl,
    this.cardTitle,
    this.cardDescription,
    this.cardDomain,
    this.articleTitle,
    this.articleContent,
    this.quoteText,
    this.quoteAuthor,
    this.expandedUrls = const [],
  });

  /// Display name for "Outlet via Display Name" formatting.
  /// Falls back to the handle without "@" when the name is empty.
  String get authorDisplayName {
    final name = authorName.trim();
    if (name.isNotEmpty) return name;
    final handle = authorHandle.trim();
    if (handle.startsWith('@') && handle.length > 1) {
      return handle.substring(1);
    }
    return handle;
  }

  /// Heuristic outlet extracted from the post content (never from URL).
  String? get resolvedCandidateOutlet =>
      candidateOutlet ?? SourcePolicy.extractOutletFromTweet(text);

  bool get isValid => text.isNotEmpty;
}
