import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/data/services/twitter_extractor.dart';
import 'package:oreamnos/data/services/twitter_article_enricher.dart';

@lazySingleton
class WebScraperService {
  WebScraperService([ApiClient? client])
    : _client = client ?? getIt<ApiClient>();

  final ApiClient _client;

  /// Checks if the input is a valid URL (Android `WebContentExtractor.isUrl`
  /// parity: allocation-free prefix scan + scheme/ www./bare-domain forms).
  static bool isUrl(String text) {
    final t = text.trim();
    if (t.length <= 5) return false;
    if (t.contains(' ')) return false;
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return true;
    }
    if (lower.startsWith('www.') && t.contains('.')) return true;
    // Bare domain: contains a dot, no spaces, suffix looks like a TLD.
    if (!t.contains('.')) return false;
    if (t.contains('@') && !t.contains('/')) return false;
    final uri = Uri.tryParse(t);
    if (uri == null) return false;
    if (uri.isScheme('http') || uri.isScheme('https')) return true;
    // No scheme — accept host-like strings (caller normalizes with https://).
    final host = t.split('/').first;
    if (!host.contains('.')) return false;
    final tld = host.split('.').last.toLowerCase();
    if (tld.length < 2 || tld.length > 6) return false;
    if (RegExp(r'[^a-z]').hasMatch(tld)) return false;
    return true;
  }

  /// Normalizes user input into a fetchable URL (adds https:// when missing).
  static String normalizeUrl(String text) {
    final t = text.trim();
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return t;
    return 'https://$t';
  }

  /// Legacy string-only extraction (kept for compat). Delegates to structured version.
  static Future<String> extractTextFromUrl(String url) async {
    final article = await extractArticleFromUrl(url);
    return article.text;
  }

  /// Static wrapper for backward compat (calls injected instance).
  static Future<ExtractedArticle> extractArticleFromUrl(String url) {
    return getIt<WebScraperService>().extractArticleFromUrlInternal(url);
  }

  /// Instance extraction via pooled Dio (with interceptors, timeout, retry).
  Future<ExtractedArticle> extractArticleFromUrlInternal(String url) async {
    final trimmed = normalizeUrl(url);

    // Intercept Twitter/X URLs
    if (TwitterExtractor.isTwitterUrl(trimmed)) {
      TweetContent? tweet = await TwitterExtractor.extractViaFxTwitter(trimmed);
      if (tweet == null || !tweet.isValid) {
        tweet = await TwitterExtractor.extractViaVxTwitter(trimmed);
      }
      if (tweet != null && tweet.isValid) {
        final enricher = getIt.isRegistered<TwitterArticleEnricher>()
            ? getIt<TwitterArticleEnricher>()
            : TwitterArticleEnricher(null, this);
        final enrichment = await enricher.enrichFromTweet(tweet.text);

        return ExtractedArticle(
          text: TwitterExtractor.formatForAiPrompt(
            tweet,
            linkedArticleContent: enrichment?.content,
            linkedArticleUrl: enrichment?.url,
          ),
          url: trimmed,
          domain: 'x.com',
          pageTitle: 'X/Twitter Post',
          siteName: null,
        );
      }
      // Fall through to normal scraping if both fail
    }

    try {
      final response = await _client.get<String>(
        trimmed,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
          },
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final uri = Uri.tryParse(trimmed);
      final domain = uri?.host ?? '';

      if (response.statusCode != 200) {
        debugPrint(
          'WebScraper warning: Failed to load page (Status ${response.statusCode}). Falling back to raw URL.',
        );
        return ExtractedArticle(
          text: trimmed,
          url: trimmed,
          domain: domain,
          pageTitle: null,
          description: null,
        );
      }

      final htmlBody = response.data ?? '';
      final document = parse(htmlBody);

      // Strip chrome/ads/nav before extraction (Android parity).
      _removeUnwantedElements(document);

      // Extract metadata
      String? pageTitle;
      String? description;
      try {
        pageTitle = document.querySelector('title')?.text.trim();
        if (pageTitle != null && pageTitle.isEmpty) pageTitle = null;
        // og:title fallback
        pageTitle ??= document
            .querySelector('meta[property="og:title"]')
            ?.attributes['content']
            ?.trim();
        description = document
            .querySelector('meta[name="description"]')
            ?.attributes['content']
            ?.trim();
        if (description != null && description.isEmpty) description = null;
        description ??= document
            .querySelector('meta[property="og:description"]')
            ?.attributes['content']
            ?.trim();
      } catch (_) {}

      String? faviconUrl;
      try {
        faviconUrl = _resolveFavicon(document, trimmed, domain);
      } catch (_) {}

      String? siteName;
      try {
        siteName = _resolveSiteName(document, pageTitle, domain);
      } catch (_) {}

      String text;
      final articleElements = document.getElementsByTagName('article');
      if (articleElements.isNotEmpty) {
        text = cleanTextPreserveParagraphs(articleElements.first.text);
      } else {
        final pElements = document.getElementsByTagName('p');
        if (pElements.isNotEmpty) {
          final buffer = StringBuffer();
          for (var p in pElements) {
            final t = p.text.trim();
            if (t.isNotEmpty) {
              if (buffer.isNotEmpty) buffer.writeln('\n');
              buffer.writeln(t);
            }
          }
          text = cleanTextPreserveParagraphs(buffer.toString());
        } else {
          text = cleanTextPreserveParagraphs(
            document.body?.text ?? 'No readable content found on this page.',
          );
        }
      }

      if (text.trim().isEmpty) {
        text = trimmed;
      }

      return ExtractedArticle(
        text: text,
        url: trimmed,
        domain: domain,
        pageTitle: pageTitle,
        description: description,
        faviconUrl: faviconUrl,
        siteName: siteName,
      );
    } catch (e) {
      throw Exception('Failed to extract content from URL: $e');
    }
  }

  /// Resolves the portal/outlet name for source.label (never a URL/domain).
  /// Priority: og:site_name → application-name → author → title suffix.
  static String? _resolveSiteName(
    dynamic document,
    String? pageTitle,
    String domain,
  ) {
    String? candidate;
    try {
      candidate = document
          .querySelector('meta[property="og:site_name"]')
          ?.attributes['content']
          ?.trim();
      if (candidate != null && candidate.isEmpty) candidate = null;
      candidate ??= document
          .querySelector('meta[name="application-name"]')
          ?.attributes['content']
          ?.trim();
      if (candidate != null && candidate.isEmpty) candidate = null;
      candidate ??= document
          .querySelector('meta[name="author"]')
          ?.attributes['content']
          ?.trim();
      if (candidate != null && candidate.isEmpty) candidate = null;
    } catch (_) {}
    if (candidate != null && candidate.isNotEmpty) {
      if (candidate.length > 60) candidate = candidate.substring(0, 60).trim();
      return candidate;
    }
    // Title suffix fallback: "Headline | BBC Sport" → "BBC Sport".
    if (pageTitle != null && pageTitle.isNotEmpty) {
      for (final sep in [' | ', ' – ', ' — ', ' - ', ' :: ']) {
        if (pageTitle.contains(sep)) {
          final parts = pageTitle.split(sep);
          final last = parts.last.trim();
          if (last.isNotEmpty &&
              last.length <= 40 &&
              !last.contains('.') &&
              last != domain) {
            return last;
          }
        }
      }
    }
    return null;
  }

  String? _resolveFavicon(dynamic document, String baseUrl, String domain) {
    var href =
        document.querySelector('link[rel="icon"]')?.attributes['href'] ??
        document.querySelector('link[rel~="icon"]')?.attributes['href'] ??
        document
            .querySelector('link[rel="apple-touch-icon"]')
            ?.attributes['href'];
    if (href == null || href.trim().isEmpty) {
      if (domain.isEmpty) return null;
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=32';
    }
    href = href.trim();
    if (href.startsWith('http')) return href;
    try {
      return Uri.parse(baseUrl).resolve(href).toString();
    } catch (_) {
      return href;
    }
  }

  /// Removes nav/ads/comments/related boilerplate before text extraction.
  static void _removeUnwantedElements(dynamic document) {
    try {
      const selectors = [
        'script',
        'style',
        'nav',
        'header',
        'footer',
        'aside',
        'form',
        '.ad',
        '.ads',
        '.advertisement',
        '.social-share',
        '.share-buttons',
        '.comments',
        '.comment-section',
        '.related-posts',
        '.related',
        '.sidebar',
        '.newsletter',
        '.popup',
        '.modal',
      ];
      for (final selector in selectors) {
        try {
          document.querySelectorAll(selector).forEach((e) => e.remove());
        } catch (_) {}
      }
    } catch (_) {}
  }

  static String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Promotional/boilerplate line patterns (Android parity).
  static final List<RegExp> _promoPatterns = [
    RegExp(r'click here.*', caseSensitive: false),
    RegExp(r'share this.*', caseSensitive: false),
    RegExp(r'subscribe.*', caseSensitive: false),
    RegExp(r'sign up for.*newsletter.*', caseSensitive: false),
  ];

  /// Preserve paragraph breaks (double newline) while collapsing intra-paragraph whitespace.
  static String cleanTextPreserveParagraphs(String text) {
    // Normalize line breaks, split into paragraphs, clean each, rejoin with \n\n
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Collapse 3+ newline runs (Android multipleNewlines parity).
    final collapsed = normalized.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    final paragraphs = collapsed.split(RegExp(r'\n\s*\n'));
    final cleaned = paragraphs
        .map((p) {
          var line = p
              .replaceAll(RegExp(r'[ \t]+'), ' ')
              .replaceAll(RegExp(r'\n\s*'), ' ')
              .trim();
          for (final pattern in _promoPatterns) {
            line = line.replaceAll(pattern, '').trim();
          }
          return line;
        })
        .where((p) => p.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return _cleanText(text);
    return cleaned.join('\n\n').trim();
  }
}
