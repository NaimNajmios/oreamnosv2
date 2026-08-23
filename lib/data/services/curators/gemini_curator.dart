import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:oreamnos/domain/services/content_curator.dart';
import 'package:oreamnos/domain/services/prompt_manager.dart';
import 'package:oreamnos/domain/services/card_prompt_manager.dart';

class GeminiCurator implements IContentCurator {
  @override
  Future<String> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required String tone,
    required String defaultHashtags,
  }) async {
    final systemPrompt = PromptManager.buildSystemPrompt(
      tone: tone,
      defaultHashtags: defaultHashtags,
    );
    final userPrompt = PromptManager.buildUserPrompt(contentOrUrl);

    // Ensure modelId doesn't have models/ prefix if it already does, or add it if needed by API
    // Actually the Gemini API uses `models/$modelId:generateContent`
    final actualModelId = modelId.startsWith('models/') ? modelId : 'models/$modelId';
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/$actualModelId:generateContent?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": systemPrompt}
          ]
        },
        "contents": [
          {
            "parts": [
              {"text": userPrompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned empty response');
    }

    final parts = candidates[0]['content']['parts'] as List<dynamic>? ?? [];
    if (parts.isEmpty) {
      throw Exception('Gemini returned empty text parts');
    }

    return parts[0]['text'] as String;
  }

  @override
  Future<String> extractCardData({
    required String generatedText,
    required String modelId,
    required String apiKey,
  }) async {
    final systemPrompt = CardPromptManager.buildSystemPrompt();
    final userPrompt = CardPromptManager.buildUserPrompt(generatedText);

    final actualModelId = modelId.startsWith('models/') ? modelId : 'models/$modelId';
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/$actualModelId:generateContent?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": systemPrompt}
          ]
        },
        "contents": [
          {
            "parts": [
              {"text": userPrompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned empty response');
    }

    final parts = candidates[0]['content']['parts'] as List<dynamic>? ?? [];
    if (parts.isEmpty) {
      throw Exception('Gemini returned empty text parts');
    }

    return parts[0]['text'] as String;
  }
}
