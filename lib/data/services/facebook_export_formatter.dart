import 'dart:convert';

import '../../domain/models/facebook_page_insights.dart';
import '../../domain/models/facebook_post_record.dart';

/// Serializes local Facebook history for export. Pure and deterministic so it
/// can be unit-tested without touching the filesystem or share sheet.
///
/// Only local records and cached insights are written. Neither model contains
/// Page tokens, so there is nothing sensitive to strip — the tests assert that
/// no token-like strings leak in from captions either.
abstract final class FacebookExportFormatter {
  static const List<String> csvHeader = [
    'id',
    'status',
    'story_status',
    'page_name',
    'page_id',
    'post_id',
    'published_at',
    'scheduled_at',
    'story_only',
    'reactions',
    'comments',
    'shares',
    'unique_viewers',
    'impressions',
    'permalink',
    'snippet',
  ];

  /// RFC 4180 CSV, newest first, with an optional performance block.
  static String buildCsv(
    List<FacebookPostRecord> records, {
    FacebookPageInsights? insights,
  }) {
    final rows = <String>[csvHeader.join(',')];
    for (final record in _sorted(records)) {
      rows.add(
        [
          record.id,
          record.status.name,
          record.storyStatus.name,
          record.pageName,
          record.pageId,
          record.postId,
          _iso(record.timestamp),
          _iso(record.scheduledAt),
          record.isStoryOnly ? 'true' : 'false',
          _value(record.reactions),
          _value(record.comments),
          _value(record.shares),
          _value(record.uniqueViewers),
          _value(record.impressions),
          record.permalink,
          record.snippet,
        ].map(_escape).join(','),
      );
    }
    if (insights != null) {
      rows
        ..add('')
        ..add(
          [
            'page_media_views',
            'page_follows',
            'page_engagements',
          ].map(_escape).join(','),
        )
        ..add(
          [
            _value(insights.totalMediaViews),
            _value(insights.totalFollows),
            _value(insights.totalEngagements),
          ].map(_escape).join(','),
        );
    }
    return rows.join('\n');
  }

  /// Machine-readable backup. Round-trips through the models' own JSON.
  static String buildJson(
    List<FacebookPostRecord> records, {
    FacebookPageInsights? insights,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'records': _sorted(records).map((r) => r.toJson()).toList(),
      if (insights != null) 'pageInsights': insights.toJson(),
    });
  }

  static List<FacebookPostRecord> _sorted(List<FacebookPostRecord> records) {
    final copy = [...records];
    copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return copy;
  }

  static String _value(int? value) => value?.toString() ?? '';

  static String _iso(DateTime? value) =>
      value?.toLocal().toIso8601String() ?? '';

  static String _escape(String value) {
    if (!value.contains(RegExp('[",\\r\\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
