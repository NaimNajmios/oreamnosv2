import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:oreamnos/domain/services/content_curator.dart';
import 'package:oreamnos/domain/services/prompt_manager.dart';
import 'package:oreamnos/domain/services/card_prompt_manager.dart';

import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

class OpenAICompatibleCurator implements IContentCurator {
  OpenAICompatibleCurator(this.baseUrl);

  final String baseUrl;

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

    final url = Uri.parse('$baseUrl/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": modelId,
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('API returned empty response');
    }

    final message = choices[0]['message'];
    return message['content'] as String;
  }

  @override
  Future<String> extractCardData({
    required String generatedText,
    required String modelId,
    required String apiKey,
    required CardTemplate template,
  }) async {
    final systemPrompt = CardPromptManager.buildSystemPrompt();
    final userPrompt = CardPromptManager.buildUserPrompt(template, generatedText);

    final url = Uri.parse('$baseUrl/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": modelId,
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": 0.3, // Lower temperature for more deterministic JSON extraction
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('API returned empty response');
    }

    final message = choices[0]['message'];
    return message['content'] as String;
  }
}
