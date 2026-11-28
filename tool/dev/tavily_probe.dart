// ignore_for_file: avoid_print
// Manual Tavily probe. Never logs a full API key.
//
//   dart run tool/dev/tavily_probe.dart "JDT beat Selangor 2-1"
//   TAVILY_API_KEY=tvly-... dart run tool/dev/tavily_probe.dart "Arsenal"
//   dart run tool/dev/tavily_probe.dart extract https://example.com/article
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final key = Platform.environment['TAVILY_API_KEY'] ?? '';
  if (key.isEmpty) {
    stderr.writeln('Set TAVILY_API_KEY (the app stores it in secure storage).');
    exitCode = 2;
    return;
  }

  final mode = args.isNotEmpty && args.first == 'extract'
      ? 'extract'
      : 'search';
  final query = mode == 'extract'
      ? (args.length > 1 ? args[1] : '')
      : (args.isNotEmpty ? args.join(' ') : 'JDT Selangor result');

  if (query.isEmpty) {
    stderr.writeln('Provide ${mode == 'extract' ? 'a URL' : 'a query'}.');
    exitCode = 2;
    return;
  }

  final endpoint = mode == 'extract'
      ? 'https://api.tavily.com/extract'
      : 'https://api.tavily.com/search';
  final body = mode == 'extract'
      ? {
          'urls': [query],
          'extract_depth': 'basic',
          'format': 'markdown',
          'include_usage': true,
        }
      : {
          'query': query,
          'topic': 'general',
          'search_depth': 'basic',
          'max_results': 4,
          'chunks_per_source': 2,
          'include_answer': false,
          'include_usage': true,
        };

  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(endpoint));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $key');
    request.write(jsonEncode(body));
    final response = await request.close();
    final raw = await utf8.decoder.bind(response).join();
    print('$endpoint → ${response.statusCode}');
    if (response.statusCode != 200) {
      stderr.writeln(raw.length > 600 ? '${raw.substring(0, 600)}…' : raw);
      exitCode = 1;
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      stderr.writeln('Unexpected response shape.');
      exitCode = 1;
      return;
    }
    print(
      'credits=${decoded['usage']?['credits'] ?? decoded['credits']} '
      'requestId=${decoded['request_id'] ?? '-'} '
      'responseTime=${decoded['response_time'] ?? '-'}',
    );

    if (mode == 'extract') {
      final results = decoded['results'] as List? ?? const [];
      final failed = decoded['failed_results'] as List? ?? const [];
      for (final r in results) {
        final text = (r['raw_content'] as String?) ?? '';
        print('chars=${text.length} preview=${_short(text, 180)}');
      }
      for (final f in failed) {
        print('FAILED ${f['url']}: ${f['error']}');
      }
      return;
    }

    final results = decoded['results'] as List? ?? const [];
    print('${results.length} result(s) for "$query"');
    for (final r in results) {
      print(
        '${(r['score'] as num?)?.toStringAsFixed(2) ?? '-'} | '
        '${r['published_date'] ?? '-'} | ${r['title']}\n'
        '  ${r['url']}\n'
        '  ${_short((r['content'] as String?) ?? '', 220)}',
      );
    }
    final answer = decoded['answer'] as String?;
    if (answer != null && answer.isNotEmpty) {
      print('answer: ${_short(answer, 300)}');
    }
  } finally {
    client.close();
  }
}

String _short(String text, int max) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= max ? flat : '${flat.substring(0, max)}…';
}
