class PromptManager {
  static String buildSystemPrompt({
    required String tone,
    required String defaultHashtags,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert AI social media curator.');
    buffer.writeln('Your task is to transform the provided football news or content into a highly engaging, Malaysian Malay social media post.');
    buffer.writeln('Tone: $tone.');
    buffer.writeln('Use relevant emojis to make the post visually appealing.');
    
    if (defaultHashtags.isNotEmpty) {
      buffer.writeln('Append the following hashtags at the very end of the post: $defaultHashtags');
    }
    
    return buffer.toString();
  }

  static String buildUserPrompt(String contentOrUrl) {
    return 'Content or URL to curate:\n$contentOrUrl';
  }
}

