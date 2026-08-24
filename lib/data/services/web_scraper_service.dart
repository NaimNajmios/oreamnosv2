import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

class WebScraperService {
  /// Checks if the input is a valid URL.
  static bool isUrl(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  /// Fetches the HTML from the URL and extracts readable text.
  static Future<String> extractTextFromUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url.trim()),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode != 200) {
        debugPrint('WebScraper warning: Failed to load page (Status ${response.statusCode}). Falling back to raw URL.');
        return url; // Fallback to sending the URL directly to the AI
      }

      final document = parse(response.body);
      
      // Try to extract text from <article> tags first
      final articleElements = document.getElementsByTagName('article');
      if (articleElements.isNotEmpty) {
        return _cleanText(articleElements.first.text);
      }

      // Fallback to extracting all <p> tags
      final pElements = document.getElementsByTagName('p');
      if (pElements.isNotEmpty) {
        final buffer = StringBuffer();
        for (var p in pElements) {
          final text = p.text.trim();
          if (text.isNotEmpty) {
            buffer.writeln(text);
          }
        }
        return _cleanText(buffer.toString());
      }

      // If no <p> tags, just get the body text
      return _cleanText(document.body?.text ?? 'No readable content found on this page.');
    } catch (e) {
      throw Exception('Failed to extract content from URL: $e');
    }
  }

  static String _cleanText(String text) {
    // Replace multiple whitespaces and newlines with a single space/newline
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

