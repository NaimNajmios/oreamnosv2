import 'package:oreamnos/domain/models/curated_post.dart';

import 'football_lexicon.dart';

class GenerationPromptManager {
  static String buildSystemPrompt({String? sourceUrl}) {
    final buf = StringBuffer();
    buf.writeln('Anda ialah kurator media sosial sukan yang pakar.');
    buf.writeln(
      'Tugas anda: transformasikan berita bola sepak yang diberikan kepada laporan media sosial yang formal, neutral dan tidak berat sebelah dalam Bahasa Melayu.',
    );
    buf.writeln(
      'Gunakan Bahasa Melayu formal sepenuhnya (gaya laporan berita sukan). Jangan gunakan sebarang emoji, emotikon atau cadangan emoji.',
    );
    buf.writeln(
      'KECUALI istilah bola sepak berikut MESTI kekal dalam Bahasa Inggeris (jangan terjemah): ${FootballLexicon.inlineList}.',
    );
    buf.writeln(
      'Tulis secara fakta dan objektif — elak bahasa provokatif, hiperbola atau sokongan pasukan. Jangan reka fakta yang tidak disebut dalam sumber.',
    );
    buf.writeln('');
    buf.writeln(
      'FORMAT OUTPUT WAJIB: Kembalikan SAHAJA satu objek JSON yang sah dengan struktur tepat:',
    );
    buf.writeln('{');
    buf.writeln(
      '  "title": "Tajuk satu baris, jelas, formal, maksimum 100 aksara, tanpa markdown atau emoji",',
    );
    buf.writeln(
      '  "body": "Kandungan utama Bahasa Melayu formal, neutral. Panjang MESTI berkadar dengan sumber asal — jangan tambah atau reka fakta. Jika sumber pendek, body pendek; jika sumber panjang, body lebih panjang tetapi kekal padat. JANGAN masukkan tajuk atau sumber di dalam body. JANGAN guna emoji.",',
    );
    buf.writeln(
      '  "source": {"label": "Nama sumber/domain", "url": "https://... atau string kosong jika tiada URL"}',
    );
    buf.writeln('}');
    buf.writeln('');
    buf.writeln('Peraturan:');
    buf.writeln(
      '- Panjang body MESTI bergantung pada sumber asal — ringkaskan sumber tanpa menambah fakta baharu, jangan panjangkan secara buatan.',
    );
    buf.writeln(
      '- Perenggan MESTI mengikut struktur kandungan sumber asal — pecahkan mengikut perubahan aspek/fakta dalam sumber, bukan rekayasa. Gunakan perenggan baharu (\\n\\n) untuk kebolehbacaan bila body melebihi satu perenggan padat.',
    );
    buf.writeln(
      '- Setiap perenggan 30-60 patah perkataan; jangan hantar satu perenggan yang terlalu panjang. Jika sumber asal hanya satu perenggan, kekalkan 1-2 perenggan padat; jika sumber ada beberapa aspek, guna 2-4 perenggan.',
    );
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      buf.writeln(
        '- Sumber input ialah URL: $sourceUrl — tetapkan source.url kepada URL tersebut dan source.label kepada domain/nama sumber.',
      );
    } else {
      buf.writeln(
        '- Jika tiada URL diberikan, tetapkan source.url kepada string kosong dan source.label kepada string kosong.',
      );
    }
    buf.writeln(
      '- Mulakan respons dengan { dan akhiri dengan }. Jangan sertakan penjelasan, preamble, markdown atau code fence di luar JSON.',
    );
    return buf.toString();
  }

  static String buildUserPrompt(dynamic content) {
    if (content is ExtractedArticle) {
      final buf = StringBuffer();
      buf.writeln(
        '<source type="article" url="${content.url}" domain="${content.domain}" pageTitle="${content.pageTitle ?? ''}">',
      );
      if (content.pageTitle != null && content.pageTitle!.isNotEmpty) {
        buf.writeln('Page Title: ${content.pageTitle}');
      }
      if (content.description != null && content.description!.isNotEmpty) {
        buf.writeln('Description: ${content.description}');
      }
      buf.writeln('');
      buf.writeln(content.text);
      buf.writeln('</source>');
      buf.writeln('');
      buf.writeln('Kembalikan JSON sahaja mengikut schema di atas.');
      return buf.toString();
    }
    if (content is String) {
      return '<source type="text">\n$content\n</source>\n\nKembalikan JSON sahaja mengikut schema di atas.';
    }
    return content.toString();
  }

  /// JSON schema for API-level structured output (Gemini responseSchema / OpenAI json_schema)
  static Map<String, dynamic> get jsonSchema => {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Tajuk formal ≤100 aksara'},
      'body': {
        'type': 'string',
        'description': 'Kandungan utama Bahasa Melayu formal, panjang berkadar dengan sumber asal, 1-4 perenggan dipisah \\n\\n, tanpa emoji, jangan reka fakta',
      },
      'source': {
        'type': 'object',
        'properties': {
          'label': {'type': 'string'},
          'url': {'type': 'string'},
        },
      },
    },
    'required': ['title', 'body', 'source'],
  };

  /// For legacy markdown fallback prompt (not used in structured flow)
  static String buildLegacySystemPrompt({
    required String tone,
    required String defaultHashtags,
  }) {
    final buf = StringBuffer();
    buf.writeln('Anda ialah kurator media sosial sukan yang pakar.');
    buf.writeln('Gunakan Bahasa Melayu formal, neutral, tanpa emoji.');
    if (defaultHashtags.isNotEmpty) {
      buf.writeln('Hashtag tambahan: $defaultHashtags');
    }
    return buf.toString();
  }

  // --- Detection helpers (parity with PromptManager.kt) ---
  static bool containsQuotes(String? text) {
    if (text == null || text.isEmpty) return false;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '"' ||
          c == '\u201C' ||
          c == '\u201D' ||
          c == "'" ||
          c == '\u2018' ||
          c == '\u2019') {
        return true;
      }
    }
    return false;
  }

  static bool containsBulletPoints(String? text) {
    if (text == null || text.isEmpty) return false;
    final lines = text.split('\n');
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('•') ||
          t.startsWith('·') ||
          t.startsWith('- ') ||
          t.startsWith('* ') ||
          t.startsWith('+ ')) {
        return true;
      }
      if (RegExp(r'^\d+\.\s').hasMatch(t) &&
          RegExp(r'^\d{1,3}\.\s').hasMatch(t)) {
        // Avoid years like 2024. — limit digitCount ≤3 via regex above
        return true;
      }
      if (RegExp(r'^\d+\)\s').hasMatch(t)) return true;
      if (RegExp(r'^[a-z]\)\s').hasMatch(t)) return true;
    }
    return false;
  }

  static bool isLongTechnicalContent(String? text) {
    if (text == null || text.length < 2000) return false;
    final lower = text.toLowerCase();
    const keywords = [
      'formation',
      'tactical',
      'pressing',
      'possession',
      'xg',
      'expected goals',
      'pass completion',
      'progressive passes',
      'defensive line',
      'build-up',
      'counter-attack',
      'high press',
      'low block',
      'transition',
      'shape',
      'midfielder',
      'forward',
      'defender',
      'fullback',
      'winger',
      '4-3-3',
      '4-4-2',
      '3-5-2',
    ];
    int hits = 0;
    for (final k in keywords) {
      if (lower.contains(k)) hits++;
      if (hits >= 5) return true;
    }
    return false;
  }
}
