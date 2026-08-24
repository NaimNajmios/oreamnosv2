import 'package:oreamnos/domain/models/curated_post.dart';

class GenerationPromptManager {
  static String buildSystemPrompt({String? sourceUrl}) {
    final buf = StringBuffer();
    buf.writeln('Anda ialah kurator media sosial sukan yang pakar.');
    buf.writeln('Tugas anda: transformasikan berita bola sepak yang diberikan kepada laporan media sosial yang formal, neutral dan tidak berat sebelah dalam Bahasa Melayu.');
    buf.writeln('Gunakan Bahasa Melayu formal sepenuhnya (gaya laporan berita sukan). Jangan gunakan sebarang emoji, emotikon atau cadangan emoji.');
    buf.writeln('Tulis secara fakta dan objektif — elak bahasa provokatif, hiperbola atau sokongan pasukan. Jangan reka fakta yang tidak disebut dalam sumber.');
    buf.writeln('');
    buf.writeln('FORMAT OUTPUT WAJIB: Kembalikan SAHAJA satu objek JSON yang sah dengan struktur tepat:');
    buf.writeln('{');
    buf.writeln('  "title": "Tajuk satu baris, jelas, formal, maksimum 100 aksara, tanpa markdown atau emoji",');
    buf.writeln('  "body": "Kandungan utama Bahasa Melayu formal, neutral. Panjang MESTI berkadar dengan sumber asal — jangan tambah atau reka fakta. Jika sumber pendek, body pendek; jika sumber panjang, body lebih panjang tetapi kekal padat. JANGAN masukkan tajuk, hashtag atau sumber di dalam body. JANGAN guna emoji.",');
    buf.writeln('  "hashtags": ["tag1", "tag2", "tag3"],');
    buf.writeln('  "source": {"label": "Nama sumber/domain", "url": "https://... atau string kosong jika tiada URL"}');
    buf.writeln('}');
    buf.writeln('');
    buf.writeln('Peraturan:');
    buf.writeln('- Panjang body MESTI bergantung pada sumber asal — ringkaskan sumber tanpa menambah fakta baharu, jangan panjangkan secara buatan.');
    buf.writeln('- Perenggan MESTI mengikut struktur kandungan sumber asal — pecahkan mengikut perubahan aspek/fakta dalam sumber, bukan rekayasa. Gunakan perenggan baharu (\\n\\n) untuk kebolehbacaan bila body melebihi satu perenggan padat.');
    buf.writeln('- Setiap perenggan 30-60 patah perkataan; jangan hantar satu perenggan yang terlalu panjang. Jika sumber asal hanya satu perenggan, kekalkan 1-2 perenggan padat; jika sumber ada beberapa aspek, guna 2-4 perenggan.');
    buf.writeln('- hashtags: 3-6 tag relevan Bahasa Melayu tanpa simbol #, tanpa emoji.');
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      buf.writeln('- Sumber input ialah URL: $sourceUrl — tetapkan source.url kepada URL tersebut dan source.label kepada domain/nama sumber.');
    } else {
      buf.writeln('- Jika tiada URL diberikan, tetapkan source.url kepada string kosong dan source.label kepada string kosong.');
    }
    buf.writeln('- Mulakan respons dengan { dan akhiri dengan }. Jangan sertakan penjelasan, preamble, markdown atau code fence di luar JSON.');
    return buf.toString();
  }

  static String buildUserPrompt(dynamic content) {
    if (content is ExtractedArticle) {
      final buf = StringBuffer();
      buf.writeln('<source type="article" url="${content.url}" domain="${content.domain}" pageTitle="${content.pageTitle ?? ''}">');
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
            'description': 'Kandungan utama Bahasa Melayu formal, panjang berkadar dengan sumber asal, 1-4 perenggan dipisah \\n\\n, tanpa emoji, jangan reka fakta'
          },
          'hashtags': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '3-6 hashtag tanpa #',
          },
          'source': {
            'type': 'object',
            'properties': {
              'label': {'type': 'string'},
              'url': {'type': 'string'},
            },
          },
        },
        'required': ['title', 'body', 'hashtags', 'source'],
      };

  /// For legacy markdown fallback prompt (not used in structured flow)
  static String buildLegacySystemPrompt({required String tone, required String defaultHashtags}) {
    final buf = StringBuffer();
    buf.writeln('Anda ialah kurator media sosial sukan yang pakar.');
    buf.writeln('Gunakan Bahasa Melayu formal, neutral, tanpa emoji.');
    if (defaultHashtags.isNotEmpty) buf.writeln('Hashtag tambahan: $defaultHashtags');
    return buf.toString();
  }
}
