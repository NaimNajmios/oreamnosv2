import 'dart:convert';
import 'dart:isolate';

class JsonCleaner {
  static String clean(String input) {
    var text = input.trim();
    // Strip markdown fences
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();
    // A double-encoded document looks like "{…}": extract the braces from
    // inside would corrupt the escapes, so decode the string as-is first.
    if (text.startsWith('"')) return text;
    // Sometimes LLM wraps with extra text before/after JSON — extract first {...}
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      text = text.substring(start, end + 1);
    }
    return text.trim();
  }

  static Map<String, dynamic> decode(String input) {
    final cleaned = clean(input);
    final decoded = _decodeDocument(cleaned);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected a JSON object');
  }

  static Future<Map<String, dynamic>> decodeIsolate(String input) async {
    // Offload JSON parsing to isolate — for large AI responses
    final cleaned = clean(input);
    final decoded = await Isolate.run(() => _decodeDocument(cleaned));
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected a JSON object');
  }

  /// Handles models that return the document as a JSON *string*
  /// (`"{\"title\":…}"`) instead of an object.
  static Object? _decodeDocument(String cleaned) {
    final value = jsonDecode(cleaned);
    if (value is String) {
      final inner = clean(value);
      if (inner.startsWith('{')) {
        return jsonDecode(inner);
      }
    }
    return value;
  }

  /// Recovers a document that was cut off mid-generation (`finishReason`
  /// `MAX_TOKENS` / `finish_reason` `length`). Without this the parse fails,
  /// the markdown fallback kicks in and the UI shows a raw `{"title":…`
  /// blob ending in a half sentence.
  ///
  /// Strategy: scan for the unterminated string, trim it back to the last
  /// complete sentence, then close the string and any open objects/arrays.
  /// Returns null when nothing sensible can be recovered.
  static Map<String, dynamic>? repairTruncated(String input) {
    final cleaned = clean(input);
    final start = cleaned.indexOf('{');
    if (start == -1) return null;
    var text = cleaned.substring(start);

    var inString = false;
    var escaped = false;
    var lastSentenceEnd = -1;

    for (var i = 0; i < text.length; i++) {
      final ch = text.codeUnitAt(i);
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == _backslash) {
          escaped = true;
        } else if (ch == _quote) {
          inString = false;
        } else if (ch == _dot || ch == _bang || ch == _question) {
          final next = i + 1 < text.length ? text.codeUnitAt(i + 1) : _space;
          // A terminator inside a JSON string is usually followed by an
          // escaped newline (`\n\n`), a space, or the closing quote.
          if (next == _space ||
              next == _newline ||
              next == _tab ||
              next == _quote ||
              next == _backslash) {
            lastSentenceEnd = i + 1;
          }
        }
      } else if (ch == _quote) {
        inString = true;
      }
    }

    if (inString) {
      if (lastSentenceEnd > 0 && lastSentenceEnd < text.length) {
        // Drop the half-written sentence, keep the complete ones.
        text = '${text.substring(0, lastSentenceEnd)}"';
      } else {
        text = '$text"';
      }
    } else {
      text = _trimDanglingToken(text);
    }

    text = '$text${_closersFor(text)}';
    try {
      final decoded = _decodeDocument(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static const int _quote = 0x22;
  static const int _backslash = 0x5C;
  static const int _dot = 0x2E;
  static const int _bang = 0x21;
  static const int _question = 0x3F;
  static const int _comma = 0x2C;
  static const int _colon = 0x3A;
  static const int _space = 0x20;
  static const int _newline = 0x0A;
  static const int _tab = 0x09;

  /// Drops a trailing `,`/`:` and any partial key left by a mid-token cut
  /// (e.g. `…,"hashtags":`), so the synthesized closers stay valid.
  static String _trimDanglingToken(String text) {
    var t = text.trimRight();
    while (t.isNotEmpty) {
      final last = t.codeUnitAt(t.length - 1);
      if (last == _comma) {
        t = t.substring(0, t.length - 1).trimRight();
      } else if (last == _colon) {
        t = t.substring(0, t.length - 1).trimRight();
        // A key whose value never started: `…,"hashtags":` → `…,`
        final key = RegExp(r'"[^"\\]*"$').firstMatch(t);
        if (key != null) t = t.substring(0, key.start).trimRight();
      } else {
        break;
      }
    }
    return t;
  }

  /// Closing characters for every structure still open at the end of [text].
  static String _closersFor(String text) {
    final stack = <int>[];
    var inString = false;
    var escaped = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text.codeUnitAt(i);
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == _backslash) {
          escaped = true;
        } else if (ch == _quote) {
          inString = false;
        }
        continue;
      }
      if (ch == _quote) {
        inString = true;
      } else if (ch == 0x7B || ch == 0x5B) {
        stack.add(ch);
      } else if (ch == 0x7D || ch == 0x5D) {
        if (stack.isNotEmpty) stack.removeLast();
      }
    }
    final buf = StringBuffer();
    for (final open in stack.reversed) {
      buf.write(open == 0x7B ? '}' : ']');
    }
    return buf.toString();
  }
}
