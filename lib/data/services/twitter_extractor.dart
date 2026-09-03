import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/core/utils/url_detector.dart';
import 'package:oreamnos/domain/services/source_policy.dart';

class TwitterExtractor {
  static final RegExp _xUrlPattern = RegExp(
    r'(?:x\.com|twitter\.com)/(\w+)/status/(\d+)',
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

    final username = match.group(1)!;
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
      );
    } catch (e) {
      debugPrint('TwitterExtractor error ($baseUrl): $e');
      return null;
    }
  }

  /// Formats tweet content into a structured block for the AI prompt.
  ///
  /// The handle/URL are metadata only and must NEVER be used as
  /// `source.label`. The label must come from POST CONTENT (see
  /// [TweetContent.candidateOutlet]) formatted as
  /// "[Outlet] via [Author Display Name]".
  static String formatForAiPrompt(TweetContent tweet) {
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
