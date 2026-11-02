import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/facebook_post_record.dart';

final facebookHistoryProvider =
    NotifierProvider<FacebookHistoryNotifier, List<FacebookPostRecord>>(
      FacebookHistoryNotifier.new,
    );

class FacebookHistoryNotifier extends Notifier<List<FacebookPostRecord>> {
  late final FacebookHistoryService _service;

  @override
  List<FacebookPostRecord> build() {
    _service = getIt<FacebookHistoryService>();
    final unsubscribe = _service.addListener((records) {
      state = records;
    });
    ref.onDispose(unsubscribe);
    return _service.records;
  }

  Future<void> remove(String id) => _service.remove(id);

  Future<void> clear() => _service.clear();
}

/// Persisted publish history (newest first, capped at 50 — the same ring
/// behaviour as `UsageService`). Backed by prefs so the list and the
/// Published Posts settings tile survive restarts.
@lazySingleton
class FacebookHistoryService {
  static const int _maxRecords = 50;

  final SharedPreferences _prefs;
  List<FacebookPostRecord> _records = [];
  final List<void Function(List<FacebookPostRecord>)> _listeners = [];

  FacebookHistoryService(this._prefs) {
    _load();
  }

  void Function() addListener(
    void Function(List<FacebookPostRecord>) listener,
  ) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener(records);
    }
  }

  List<FacebookPostRecord> get records => List.unmodifiable(_records);

  void _load() {
    try {
      final list = _prefs.getStringList(AppConstants.keyFacebookHistory) ?? [];
      _records = list
          .map((e) => FacebookPostRecord.fromJson(jsonDecode(e)))
          .toList();
    } catch (_) {
      _records = [];
    }
    _notify();
  }

  /// Adds a successful publish. Returns the created record.
  Future<FacebookPostRecord> recordPublish({
    required String postId,
    required String message,
    required String permalink,
    required bool hasImage,
  }) async {
    final snippet = message.trim().isEmpty
        ? (hasImage ? 'Card post' : 'Text post')
        : message.trim().split('\n').first;
    final record = FacebookPostRecord(
      id: const Uuid().v4(),
      postId: postId,
      snippet: snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet,
      timestamp: DateTime.now(),
      hasImage: hasImage,
      permalink: permalink,
    );
    _records = List.of(_records)..insert(0, record);
    if (_records.length > _maxRecords) {
      _records = _records.sublist(0, _maxRecords);
    }
    try {
      await _prefs.setStringList(
        AppConstants.keyFacebookHistory,
        _records.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (_) {}
    _notify();
    return record;
  }

  Future<void> remove(String id) async {
    _records = List.of(_records)..removeWhere((r) => r.id == id);
    try {
      await _prefs.setStringList(
        AppConstants.keyFacebookHistory,
        _records.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (_) {}
    _notify();
  }

  Future<void> clear() async {
    _records = [];
    await _prefs.remove(AppConstants.keyFacebookHistory);
    _notify();
  }
}
