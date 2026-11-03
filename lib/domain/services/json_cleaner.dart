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
}
