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
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> decodeIsolate(String input) async {
    // Offload JSON parsing to isolate — for large AI responses
    final cleaned = clean(input);
    return await Isolate.run(() => jsonDecode(cleaned) as Map<String, dynamic>);
  }
}
