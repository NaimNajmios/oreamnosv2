import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';

/// One saved draft. Media stays as raw JSON so the data layer never imports
/// the UI model; the view model converts it to `FacebookMediaItem`.
class FacebookDraftRecord {
  const FacebookDraftRecord({
    required this.id,
    required this.text,
    required this.media,
    required this.pageId,
    required this.pageName,
    required this.mode,
    required this.updatedAt,
    this.scheduledAt,
    this.workflowId = '',
    this.workflowName = '',
    this.publishFeed = true,
    this.storyEnabled = false,
    this.storyTitle = '',
  });

  final String id;
  final String text;
  final List<Map<String, dynamic>> media;
  final String pageId;
  final String pageName;
  final String mode;
  final DateTime? scheduledAt;
  final DateTime updatedAt;
  final String workflowId;
  final String workflowName;
  final bool publishFeed;
  final bool storyEnabled;
  final String storyTitle;

  bool get isEmpty =>
      text.trim().isEmpty &&
      media.every((m) => (m['path'] ?? '').toString().isEmpty);

  FacebookDraftRecord copyWith({
    String? text,
    List<Map<String, dynamic>>? media,
    String? pageId,
    String? pageName,
    String? mode,
    Object? scheduledAt = _sentinel,
    DateTime? updatedAt,
    String? workflowId,
    String? workflowName,
    bool? publishFeed,
    bool? storyEnabled,
    String? storyTitle,
  }) {
    return FacebookDraftRecord(
      id: id,
      text: text ?? this.text,
      media: media ?? this.media,
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      mode: mode ?? this.mode,
      scheduledAt: scheduledAt == _sentinel
          ? this.scheduledAt
          : scheduledAt as DateTime?,
      updatedAt: updatedAt ?? this.updatedAt,
      workflowId: workflowId ?? this.workflowId,
      workflowName: workflowName ?? this.workflowName,
      publishFeed: publishFeed ?? this.publishFeed,
      storyEnabled: storyEnabled ?? this.storyEnabled,
      storyTitle: storyTitle ?? this.storyTitle,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'media': media,
    'pageId': pageId,
    'pageName': pageName,
    'mode': mode,
    'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'workflowId': workflowId,
    'workflowName': workflowName,
    'publishFeed': publishFeed,
    'storyEnabled': storyEnabled,
    'storyTitle': storyTitle,
  };

  factory FacebookDraftRecord.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final media = rawMedia is List
        ? rawMedia
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    return FacebookDraftRecord(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      media: media,
      pageId: json['pageId']?.toString() ?? '',
      pageName: json['pageName']?.toString() ?? '',
      mode: json['mode']?.toString() == 'scheduled' ? 'scheduled' : 'now',
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? '')
          ?.toLocal(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      workflowId: json['workflowId']?.toString() ?? '',
      workflowName: json['workflowName']?.toString() ?? '',
      publishFeed: json['publishFeed'] as bool? ?? true,
      storyEnabled: json['storyEnabled'] as bool? ?? false,
      storyTitle: json['storyTitle']?.toString() ?? '',
    );
  }

  static const Object _sentinel = Object();
}

/// Persists multiple drafts (cap 20, newest first) with their images copied
/// into app documents so OS temp cleanup cannot break them.
@lazySingleton
class FacebookDraftStore {
  static const int maxDrafts = 20;

  FacebookDraftStore(this._prefs);

  final SharedPreferences _prefs;

  List<FacebookDraftRecord> loadAll() {
    final raw = _prefs.getString(AppConstants.keyFacebookDrafts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final records = decoded
          .whereType<Map>()
          .map((e) => FacebookDraftRecord.fromJson(e.cast<String, dynamic>()))
          .where((r) => r.id.isNotEmpty)
          .toList();
      records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return records;
    } catch (_) {
      return const [];
    }
  }

  String? get activeDraftId =>
      _prefs.getString(AppConstants.keyFacebookActiveDraft);

  FacebookDraftRecord? loadActive() {
    final id = activeDraftId;
    if (id == null || id.isEmpty) return null;
    for (final record in loadAll()) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<void> setActive(String? id) async {
    if (id == null || id.isEmpty) {
      await clearActive();
    } else {
      await _prefs.setString(AppConstants.keyFacebookActiveDraft, id);
    }
  }

  Future<void> clearActive() async {
    await _prefs.remove(AppConstants.keyFacebookActiveDraft);
  }

  Future<void> save(FacebookDraftRecord record) async {
    final records = [...loadAll()];
    final index = records.indexWhere((r) => r.id == record.id);
    if (index < 0) {
      records.insert(0, record);
    } else {
      records[index] = record;
    }
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final capped = records.take(maxDrafts).toList();
    await _persist(capped);
    await setActive(record.id);
    // Delete images belonging to drafts evicted by the cap.
    for (final evicted in records.skip(maxDrafts)) {
      await _deleteDraftImages(evicted.id);
    }
    // Drop files for photos removed from this draft.
    await pruneDraftMedia(record.id);
  }

  Future<void> delete(String id) async {
    final records = loadAll().where((r) => r.id != id).toList();
    await _persist(records);
    if (activeDraftId == id) await clearActive();
    await _deleteDraftImages(id);
  }

  /// Copies a draft (and its images) under a new id. Returns the new id.
  Future<String?> duplicate(String id) async {
    FacebookDraftRecord? source;
    for (final record in loadAll()) {
      if (record.id == id) {
        source = record;
        break;
      }
    }
    if (source == null) return null;
    final newId = const Uuid().v4();
    final media = await importMedia(newId, source.media);
    final copy = FacebookDraftRecord(
      id: newId,
      text: source.text,
      media: media,
      pageId: source.pageId,
      pageName: source.pageName,
      mode: source.mode,
      scheduledAt: source.scheduledAt,
      updatedAt: DateTime.now(),
      workflowId: source.workflowId,
      workflowName: source.workflowName,
      publishFeed: source.publishFeed,
      storyEnabled: source.storyEnabled,
      storyTitle: source.storyTitle,
    );
    await save(copy);
    return newId;
  }

  /// Copies each media file into `<docs>/facebook_drafts/<draftId>/` and
  /// returns JSON with rewritten paths. Safe to call repeatedly.
  Future<List<Map<String, dynamic>>> importMedia(
    String draftId,
    List<Map<String, dynamic>> media,
  ) async {
    final dir = await _draftDir(draftId);
    if (dir == null) return media;
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < media.length; i++) {
      final item = Map<String, dynamic>.of(media[i]);
      final source = (item['path'] ?? '').toString();
      if (source.isEmpty) {
        result.add(item);
        continue;
      }
      try {
        if (!dir.existsSync()) await dir.create(recursive: true);
        if (!source.startsWith(dir.path)) {
          final ext = _extensionOf(source);
          final target = File('${dir.path}/$i$ext');
          await File(source).copy(target.path);
          item['path'] = target.path;
        }
      } catch (_) {
        // Keep the original path; publish pre-flight reports a missing file.
      }
      result.add(item);
    }
    return result;
  }

  /// Converts the v10 single-draft prefs key into a store record. Idempotent.
  Future<String?> migrateLegacyDraft() async {
    if (loadAll().isNotEmpty) return null;
    final raw = _prefs.getString(AppConstants.keyFacebookDraft);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final map = json.cast<String, dynamic>();
      final id = const Uuid().v4();
      final rawMedia = map['media'];
      final media = rawMedia is List
          ? rawMedia
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList(growable: false)
          : <Map<String, dynamic>>[
              if ((map['imagePath'] as String? ?? '').isNotEmpty)
                {'path': map['imagePath'], 'aspect': map['aspect']},
            ];
      final imported = await importMedia(id, media);
      final record = FacebookDraftRecord(
        id: id,
        text: map['text']?.toString() ?? '',
        media: imported,
        pageId: '',
        pageName: '',
        mode: map['mode']?.toString() == 'scheduled' ? 'scheduled' : 'now',
        scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '')
            ?.toLocal(),
        updatedAt: DateTime.now(),
      );
      await save(record);
      await _prefs.remove(AppConstants.keyFacebookDraft);
      return id;
    } catch (_) {
      return null;
    }
  }

  /// Deletes image folders that no longer belong to a saved draft.
  Future<void> pruneOrphans() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final root = Directory('${docs.path}/facebook_drafts');
      if (!root.existsSync()) return;
      final live = loadAll().map((r) => r.id).toSet();
      for (final entity in root.listSync()) {
        if (entity is! Directory) continue;
        final name = entity.path.replaceAll('\\', '/').split('/').last;
        if (live.contains(name)) continue;
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Deletes files inside one draft folder that are no longer referenced by
  /// its media list. Returns bytes freed.
  Future<int> pruneDraftMedia(String draftId) async {
    final dir = await _draftDir(draftId);
    if (dir == null || !dir.existsSync()) return 0;
    FacebookDraftRecord? record;
    for (final item in loadAll()) {
      if (item.id == draftId) {
        record = item;
        break;
      }
    }
    if (record == null) return 0;
    final keep = record.media
        .map((m) => _normalize((m['path'] ?? '').toString()))
        .where((p) => p.isNotEmpty)
        .toSet();
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

  /// Sweeps every live draft folder and removes folders whose record is gone.
  /// Returns bytes freed. Safe to call at startup.
  Future<int> sweepAll() async {
    var freed = 0;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final root = Directory('${docs.path}/facebook_drafts');
      if (!root.existsSync()) return 0;
      final records = loadAll();
      final live = records.map((r) => r.id).toSet();
      for (final entity in root.listSync()) {
        if (entity is! Directory) continue;
        final name = entity.path.replaceAll('\\', '/').split('/').last;
        if (live.contains(name)) continue;
        freed += await _directorySize(entity);
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
      for (final record in records) {
        freed += await pruneDraftMedia(record.id);
      }
    } catch (_) {}
    return freed;
  }

  static String _normalize(String path) =>
      path.replaceAll('\\', '/').toLowerCase();

  static Future<int> _directorySize(Directory dir) async {
    var total = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  Future<void> _persist(List<FacebookDraftRecord> records) async {
    await _prefs.setString(
      AppConstants.keyFacebookDrafts,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  Future<Directory?> _draftDir(String id) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      return Directory('${docs.path}/facebook_drafts/$id');
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteDraftImages(String id) async {
    final dir = await _draftDir(id);
    if (dir == null) return;
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '.png';
    final ext = path.substring(dot);
    return ext.length <= 5 ? ext : '.png';
  }
}
