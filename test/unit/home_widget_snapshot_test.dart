import 'package:flutter_test/flutter_test.dart';

import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/domain/models/home_widget_snapshot.dart';
import 'package:oreamnos/domain/services/home_widget_snapshot_builder.dart';

const _palette = HomeWidgetPalette(
  surface: 0xFF121212,
  onSurface: 0xFFFFFFFF,
  muted: 0xFFB0B3B8,
  primary: 0xFF0095F6,
);

FacebookPostRecord _record({
  required String id,
  DateTime? scheduledAt,
  String snippet = 'Kelayakan Piala Asia: Malaysia bertemu Vietnam',
  String pageName = 'Football Malaysia',
  FacebookPostStatus status = FacebookPostStatus.scheduled,
  bool isStoryOnly = false,
}) {
  final timestamp = DateTime(2026, 11, 14, 12);
  return FacebookPostRecord(
    id: id,
    postId: id,
    snippet: snippet,
    timestamp: timestamp,
    hasImage: false,
    permalink: '',
    status: status,
    scheduledAt: scheduledAt,
    pageName: pageName,
    isStoryOnly: isStoryOnly,
  );
}

HomeWidgetSnapshot _build({
  required List<FacebookPostRecord> records,
  List<HomeWidgetQuota> quotas = const [],
  String pageName = 'Football Malaysia',
  bool pageConnected = true,
  bool pageExpired = false,
  int draftCount = 0,
  String? selectedProviderId = 'gemini',
  String? selectedModel = 'gemini-2.5-flash',
  DateTime? now,
}) {
  final reference = now ?? DateTime(2026, 11, 14, 12);
  return const HomeWidgetSnapshotBuilder().build(
    now: reference,
    records: records,
    quotas: quotas,
    pageName: pageName,
    pageConnected: pageConnected,
    pageExpired: pageExpired,
    draftCount: draftCount,
    palette: _palette,
    selectedProviderId: selectedProviderId,
    selectedModel: selectedModel,
    quotaResetAt: quotas.isEmpty
        ? null
        : reference.add(const Duration(hours: 6)),
  );
}

void main() {
  group('HomeWidgetSnapshotBuilder next-up', () {
    test('picks the soonest scheduled post and ignores published ones', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'later',
            scheduledAt: DateTime(2026, 11, 14, 20, 45),
            snippet: 'Later post',
          ),
          _record(
            id: 'published',
            status: FacebookPostStatus.published,
            snippet: 'Already live',
          ),
          _record(
            id: 'sooner',
            scheduledAt: DateTime(2026, 11, 14, 14, 30),
            snippet: 'Sooner post',
            pageName: 'Harian Bola',
          ),
        ],
      );

      expect(snapshot.nextSnippet, 'Sooner post');
      expect(snapshot.nextAt, DateTime(2026, 11, 14, 14, 30));
      expect(snapshot.nextPage, 'Harian Bola');
      expect(snapshot.scheduledCount, 2);
    });

    test('empty schedule degrades to an empty next-up, not a null crash', () {
      final snapshot = _build(
        records: [_record(id: 'done', status: FacebookPostStatus.published)],
      );

      expect(snapshot.nextSnippet, isEmpty);
      expect(snapshot.nextAt, isNull);
      expect(snapshot.scheduledCount, 0);
      expect(snapshot.toMap()[HomeWidgetKeys.nextAt], isEmpty);
    });

    test('carries the Story-only flag', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'story',
            scheduledAt: DateTime(2026, 11, 14, 18),
            isStoryOnly: true,
          ),
        ],
      );

      expect(snapshot.nextIsStory, isTrue);
    });

    test('collapses whitespace and truncates long snippets', () {
      final long = 'A' * 200;
      final snapshot = _build(
        records: [
          _record(
            id: 'long',
            scheduledAt: DateTime(2026, 11, 14, 13),
            snippet: 'Line one\n\n  line   two $long',
          ),
        ],
      );

      expect(snapshot.nextSnippet, isNot(contains('\n')));
      expect(
        snapshot.nextSnippet.length,
        lessThanOrEqualTo(HomeWidgetSnapshotBuilder.maxSnippetChars),
      );
      expect(snapshot.nextSnippet, endsWith('…'));
    });
  });

  group('HomeWidgetSnapshotBuilder quota', () {
    const quotas = [
      HomeWidgetQuota(
        modelId: 'gemini-2.5-flash',
        requestsToday: 312,
        budget: 500,
      ),
      HomeWidgetQuota(
        modelId: 'gemini-2.0-flash-lite',
        requestsToday: 40,
        budget: 1500,
      ),
    ];

    test('prefers the selected model, including a models/ prefix', () {
      final snapshot = _build(
        records: const [],
        quotas: quotas,
        selectedModel: 'models/gemini-2.5-flash',
      );

      expect(snapshot.quotaModel, '2.5-flash');
      expect(snapshot.quotaUsed, 312);
      expect(snapshot.quotaBudget, 500);
    });

    test('falls back to the busiest model when the selection is unknown', () {
      final snapshot = _build(
        records: const [],
        quotas: quotas,
        selectedModel: 'gemini-3.0-pro',
      );

      expect(snapshot.quotaModel, '2.5-flash');
    });

    test('falls back to the busiest model for a non-Gemini provider', () {
      final snapshot = _build(
        records: const [],
        quotas: quotas,
        selectedProviderId: 'groq',
        selectedModel: 'llama-3.3-70b-versatile',
      );

      expect(snapshot.quotaModel, '2.5-flash');
    });

    test('no quota activity hides the quota half and its reset', () {
      final snapshot = _build(records: const [], quotas: const []);

      expect(snapshot.hasQuota, isFalse);
      expect(snapshot.quotaUsed, isNull);
      expect(snapshot.quotaResetAt, isNull);
      final map = snapshot.toMap();
      expect(map[HomeWidgetKeys.quotaUsed], isEmpty);
      expect(map[HomeWidgetKeys.quotaBudget], isEmpty);
      expect(map[HomeWidgetKeys.quotaResetAt], isEmpty);
    });
  });

  test('payload only contains whitelisted string keys', () {
    final snapshot = _build(
      records: [_record(id: 'x', scheduledAt: DateTime(2026, 11, 14, 15))],
      quotas: const [
        HomeWidgetQuota(
          modelId: 'gemini-2.5-flash',
          requestsToday: 10,
          budget: 500,
        ),
      ],
      draftCount: 2,
    );

    final map = snapshot.toMap();
    expect(map.keys.toSet(), HomeWidgetKeys.all);
    for (final entry in map.entries) {
      expect(
        entry.value,
        isA<String>(),
        reason: '${entry.key} must be a String for the native reader',
      );
    }

    // A home-screen surface must never carry a credential or a permalink.
    for (final key in map.keys) {
      final lower = key.toLowerCase();
      expect(lower, isNot(contains('token')));
      expect(lower, isNot(contains('permalink')));
      expect(lower, isNot(contains('secret')));
    }
  });

  test('colours serialize as 8-digit uppercase ARGB hex', () {
    final map = _build(records: const []).toMap();

    expect(map[HomeWidgetKeys.surface], '#FF121212');
    expect(map[HomeWidgetKeys.primary], '#FF0095F6');
    expect(map[HomeWidgetKeys.onSurface], '#FFFFFFFF');
  });

  test('epoch fields are millisecond strings', () {
    final at = DateTime(2026, 11, 14, 14, 30);
    final map = _build(
      records: [_record(id: 'x', scheduledAt: at)],
      quotas: const [
        HomeWidgetQuota(
          modelId: 'gemini-2.5-flash',
          requestsToday: 1,
          budget: 500,
        ),
      ],
      now: at,
    ).toMap();

    expect(map[HomeWidgetKeys.nextAt], '${at.millisecondsSinceEpoch}');
    expect(
      map[HomeWidgetKeys.quotaResetAt],
      '${at.add(const Duration(hours: 6)).millisecondsSinceEpoch}',
    );
  });
}
