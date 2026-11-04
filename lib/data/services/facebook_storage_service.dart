import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import 'facebook_draft_store.dart';
import 'facebook_history_service.dart';

class FacebookStorageReport {
  const FacebookStorageReport({
    this.historyThumbnailBytes = 0,
    this.draftImageBytes = 0,
    this.tempUploadBytes = 0,
    this.draftCount = 0,
    this.thumbnailCount = 0,
    this.tempFileCount = 0,
  });

  final int historyThumbnailBytes;
  final int draftImageBytes;
  final int tempUploadBytes;
  final int draftCount;
  final int thumbnailCount;
  final int tempFileCount;

  int get totalBytes =>
      historyThumbnailBytes + draftImageBytes + tempUploadBytes;

  String get formattedTotal => _formatBytes(totalBytes);

  String get formattedHistory => _formatBytes(historyThumbnailBytes);

  String get formattedDrafts => _formatBytes(draftImageBytes);

  String get formattedTemp => _formatBytes(tempUploadBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Measures and cleans only Facebook-owned files: history thumbnails, draft
/// images, and old cropped uploads in the temp directory.
@lazySingleton
class FacebookStorageService {
  FacebookStorageService(this._history, this._drafts);

  final FacebookHistoryService _history;
  final FacebookDraftStore _drafts;

  static const Duration staleUploadAge = Duration(hours: 24);
  static const String _tempPrefix = 'oreamnos_fb_';

  Future<FacebookStorageReport> report() async {
    final docs = await _documents();
    final temp = await getTemporaryDirectory();
    final thumbs = docs == null
        ? (bytes: 0, count: 0)
        : await _measure(Directory('${docs.path}/facebook_thumbs'));
    final draftRoot = docs == null
        ? (bytes: 0, count: 0)
        : await _measure(Directory('${docs.path}/facebook_drafts'));
    final tempUploads = await _measureTemp(temp);
    return FacebookStorageReport(
      historyThumbnailBytes: thumbs.bytes,
      thumbnailCount: thumbs.count,
      draftImageBytes: draftRoot.bytes,
      draftCount: _drafts.loadAll().length,
      tempUploadBytes: tempUploads.bytes,
      tempFileCount: tempUploads.count,
    );
  }

  /// Deletes unreferenced thumbnails, draft files/folders, and stale temp
  /// crops. Returns bytes freed.
  Future<int> sweep() async {
    var freed = 0;
    final docs = await _documents();
    if (docs != null) {
      freed += await _sweepThumbnails(
        Directory('${docs.path}/facebook_thumbs'),
      );
    }
    freed += await _drafts.sweepAll();
    final temp = await getTemporaryDirectory();
    freed += await _sweepTemp(temp);
    return freed;
  }

  Future<int> _sweepThumbnails(Directory dir) async {
    if (!dir.existsSync()) return 0;
    final keep = <String>{};
    for (final record in _history.records) {
      for (final path in record.localImagePaths) {
        keep.add(_normalize(path));
      }
      if (record.storyImagePath.isNotEmpty) {
        keep.add(_normalize(record.storyImagePath));
      }
    }
    var freed = 0;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      if (keep.contains(_normalize(entity.path))) continue;
      try {
        freed += await entity.length();
        await entity.delete();
      } catch (_) {}
    }
    return freed;
  }

  Future<int> _sweepTemp(Directory dir) async {
    if (!dir.existsSync()) return 0;
    final cutoff = DateTime.now().subtract(staleUploadAge);
    var freed = 0;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last;
      if (!name.startsWith(_tempPrefix)) continue;
      try {
        final stat = await entity.stat();
        if (stat.modified.isAfter(cutoff)) continue;
        freed += stat.size;
        await entity.delete();
      } catch (_) {}
    }
    return freed;
  }

  Future<({int bytes, int count})> _measure(Directory dir) async {
    if (!dir.existsSync()) return (bytes: 0, count: 0);
    var bytes = 0;
    var count = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        try {
          bytes += await entity.length();
          count++;
        } catch (_) {}
      }
    } catch (_) {}
    return (bytes: bytes, count: count);
  }

  Future<({int bytes, int count})> _measureTemp(Directory dir) async {
    if (!dir.existsSync()) return (bytes: 0, count: 0);
    var bytes = 0;
    var count = 0;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last;
      if (!name.startsWith(_tempPrefix)) continue;
      try {
        bytes += await entity.length();
        count++;
      } catch (_) {}
    }
    return (bytes: bytes, count: count);
  }

  Future<Directory?> _documents() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return null;
    }
  }

  static String _normalize(String path) =>
      path.replaceAll('\\', '/').toLowerCase();
}
