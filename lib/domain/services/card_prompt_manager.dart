class CardPromptManager {
  static String buildSystemPrompt() {
    return '''You are an expert content analyzer for social media.
Your task is to extract structured information from the provided text to generate a visually appealing informational card.

You must reply ONLY with a valid JSON object matching this exact schema, with no markdown formatting or extra text:

{
  "title": "A short, punchy 3-5 word headline summarizing the core message",
  "subtitle": "A slightly longer 1-2 sentence context or subtitle",
  "quote": "An optional impactful quote extracted from the text (null if none exists)",
  "keyPoints": [
    "A concise point 1",
    "A concise point 2",
    "A concise point 3 (optional, max 4)"
  ]
}

Ensure the JSON is strictly valid, unescaped properly, and contains NO markdown backticks like ```json.''';
  }

  static String buildUserPrompt(String generatedText) {
    return 'Extract the information into the JSON format based on the following content:\n\n$generatedText';
  }
}

