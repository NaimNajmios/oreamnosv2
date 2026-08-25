import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';
import 'package:oreamnos/domain/models/curated_post.dart';

class WebScraperService {
  /// Checks if the input is a valid URL.
  static bool isUrl(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  /// Legacy string-only extraction (kept for compat). Delegates to structured version.
  static Future<String> extractTextFromUrl(String url) async {
    final article = await extractArticleFromUrl(url);
    return article.text;
  }

  /// Structured extraction preserving metadata.
  static Future<ExtractedArticle> extractArticleFromUrl(String url) async {
    final trimmed = url.trim();
    try {
      final response = await http.get(
        Uri.parse(trimmed),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      ).timeout(const Duration(seconds: 8));

      final uri = Uri.tryParse(trimmed);
      final domain = uri?.host ?? '';

      if (response.statusCode != 200) {
        debugPrint('WebScraper warning: Failed to load page (Status ${response.statusCode}). Falling back to raw URL.');
        return ExtractedArticle(text: trimmed, url: trimmed, domain: domain, pageTitle: null, description: null);
      }

      final document = parse(response.body);

      // Extract metadata
      String? pageTitle;
      String? description;
      try {
        pageTitle = document.querySelector('title')?.text.trim();
        if (pageTitle != null && pageTitle.isEmpty) pageTitle = null;
        // og:title fallback
        pageTitle ??= document.querySelector('meta[property="og:title"]')?.attributes['content']?.trim();
        description = document.querySelector('meta[name="description"]')?.attributes['content']?.trim();
        if (description != null && description.isEmpty) description = null;
        description ??= document.querySelector('meta[property="og:description"]')?.attributes['content']?.trim();
      } catch (_) {}

      String text;
      final articleElements = document.getElementsByTagName('article');
      if (articleElements.isNotEmpty) {
        text = _cleanTextPreserveParagraphs(articleElements.first.text);
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
          text = _cleanTextPreserveParagraphs(buffer.toString());
        } else {
          text = _cleanTextPreserveParagraphs(document.body?.text ?? 'No readable content found on this page.');
        }
      }

      if (text.trim().isEmpty) {
        text = trimmed;
      }

      return ExtractedArticle(text: text, url: trimmed, domain: domain, pageTitle: pageTitle, description: description);
    } catch (e) {
      throw Exception('Failed to extract content from URL: $e');
    }
  }

  static String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Preserve paragraph breaks (double newline) while collapsing intra-paragraph whitespace.
  static String _cleanTextPreserveParagraphs(String text) {
    // Normalize line breaks, split into paragraphs, clean each, rejoin with \n\n
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final paragraphs = normalized.split(RegExp(r'\n\s*\n'));
    final cleaned = paragraphs
        .map((p) => p.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n\s*'), ' ').trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return _cleanText(text);
    return cleaned.join('\n\n').trim();
  }
}

