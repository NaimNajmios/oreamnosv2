import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/core/utils/url_detector.dart';

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

  /// Formats tweet content into a rich text block for the AI prompt
  static String formatForAiPrompt(TweetContent tweet) {
    final sb = StringBuffer();
    sb.writeln('SOURCE: X/Twitter Post');
    sb.writeln('AUTHOR: ${tweet.authorName} (${tweet.authorHandle})');
    sb.writeln('DATE: ${tweet.createdAt}');
    sb.writeln(
      'ENGAGEMENT: ${tweet.likes} likes, ${tweet.retweets} retweets, ${tweet.views} views',
    );
    sb.writeln('');
    sb.writeln('POST CONTENT:');
    sb.writeln(tweet.text);
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
  });

  bool get isValid => text.isNotEmpty;
}
