import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/facebook_page_insights.dart';
import '../../domain/models/facebook_post_record.dart';
import 'facebook_export_formatter.dart';

enum FacebookExportFormat {
  csv('csv', 'text/csv'),
  json('json', 'application/json');

  const FacebookExportFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}

/// Writes a Facebook history export to a temp file and hands it to the OS
/// share sheet. Tokens are never part of the exported models.
@lazySingleton
class FacebookExportService {
  FacebookExportService({Future<Directory> Function()? tempDirectory})
    : _tempDirectory = tempDirectory ?? getTemporaryDirectory;

  final Future<Directory> Function() _tempDirectory;

  Future<File> write({
    required FacebookExportFormat format,
    required List<FacebookPostRecord> records,
    FacebookPageInsights? insights,
  }) async {
    final dir = await _tempDirectory();
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final file = File(
      '${dir.path}/oreamnos_facebook_history_$stamp.${format.extension}',
    );
    final content = switch (format) {
      FacebookExportFormat.csv => FacebookExportFormatter.buildCsv(
        records,
        insights: insights,
      ),
      FacebookExportFormat.json => FacebookExportFormatter.buildJson(
        records,
        insights: insights,
      ),
    };
    // A UTF-8 BOM keeps Excel from mangling non-ASCII Page names and captions.
    final bytes = format == FacebookExportFormat.csv
        ? <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(content)]
        : utf8.encode(content);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> share(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: _mimeFor(file.path))],
        subject: 'Oreamnos Facebook history',
      ),
    );
  }

  static String _mimeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.json')) return FacebookExportFormat.json.mimeType;
    return FacebookExportFormat.csv.mimeType;
  }
}
