import 'dart:convert';

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
  DateTime? timestamp,
  String snippet = 'Kelayakan Piala Asia: Malaysia bertemu Vietnam',
  String pageName = 'Football Malaysia',
  String pageId = 'page-1',
  FacebookPostStatus status = FacebookPostStatus.scheduled,
  FacebookStoryStatus storyStatus = FacebookStoryStatus.none,
  bool isStoryOnly = false,
  int? reactions,
  int? comments,
  int? shares,
}) {
  final at = timestamp ?? DateTime(2026, 11, 14, 12);
  return FacebookPostRecord(
    id: id,
    postId: id,
    snippet: snippet,
    timestamp: at,
    hasImage: false,
    permalink: '',
    status: status,
    scheduledAt: scheduledAt,
    pageName: pageName,
    pageId: pageId,
    storyStatus: storyStatus,
    isStoryOnly: isStoryOnly,
    reactions: reactions,
    comments: comments,
    shares: shares,
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
  Map<String, List<int>> quotaHistory = const {},
  List<HomeWidgetPage> pages = const [],
  String draftTitle = '',
  bool showSnippet = true,
  HomeWidgetSecondRow secondRow = HomeWidgetSecondRow.quota,
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
    quotaHistory: quotaHistory,
    pages: pages,
    draftTitle: draftTitle,
    showSnippet: showSnippet,
    secondRow: secondRow,
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
      expect(lower, isNot(contains('api_key')));
    }

    // Long captions belong in the app, not on a shared home screen.
    for (final entry in map.entries) {
      if (entry.key == HomeWidgetKeys.pagesJson) continue;
      expect(
        entry.value.length,
        lessThanOrEqualTo(HomeWidgetSnapshotBuilder.maxPayloadChars),
        reason: '${entry.key} exceeds the payload cap',
      );
    }
    expect(
      map[HomeWidgetKeys.pagesJson]!.length,
      lessThanOrEqualTo(HomeWidgetSnapshotBuilder.maxPagesJsonChars),
    );
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

  group('caption privacy', () {
    test('off: no caption substring survives in the payload', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'secret',
            scheduledAt: DateTime(2026, 11, 14, 15),
            snippet: 'Secret derby lineup reveal',
          ),
        ],
        pages: const [HomeWidgetPage(id: 'page-1', name: 'Football Malaysia')],
        showSnippet: false,
      );

      expect(snapshot.nextSnippet, isEmpty);
      expect(snapshot.toMap()[HomeWidgetKeys.nextSnippet], isEmpty);
      expect(snapshot.pagesJson, isNot(contains('Secret')));
      expect(snapshot.toMap().values.join(), isNot(contains('Secret')));
    });

    test('on: the caption is carried and capped', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'x',
            scheduledAt: DateTime(2026, 11, 14, 15),
            snippet: 'B' * 300,
          ),
        ],
      );

      expect(snapshot.nextSnippet, isNotEmpty);
      expect(
        snapshot.nextSnippet.length,
        lessThanOrEqualTo(HomeWidgetSnapshotBuilder.maxSnippetChars),
      );
    });
  });

  group('last post engagement', () {
    test('picks the newest published post with full metrics', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'old',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 10, 9),
            snippet: 'Old post',
            reactions: 10,
          ),
          _record(
            id: 'new',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 13, 9),
            snippet: 'Newest post',
            reactions: 128,
            comments: 24,
            shares: 9,
          ),
        ],
      );

      expect(snapshot.lastPostSnippet, 'Newest post');
      expect(snapshot.lastPostReactions, 128);
      expect(snapshot.lastPostComments, 24);
      expect(snapshot.lastPostShares, 9);
      expect(snapshot.lastPostAt, DateTime(2026, 11, 13, 9));
      expect(snapshot.hasLastPost, isTrue);
    });

    test('keeps partial metrics and hides the row with none', () {
      final partial = _build(
        records: [
          _record(
            id: 'partial',
            status: FacebookPostStatus.published,
            reactions: 7,
          ),
        ],
      );
      expect(partial.hasLastPost, isTrue);
      expect(partial.lastPostComments, isNull);

      final none = _build(
        records: [
          _record(id: 'bare', status: FacebookPostStatus.published),
          _record(id: 'sched', scheduledAt: DateTime(2026, 11, 14, 18)),
        ],
      );
      expect(none.hasLastPost, isFalse);
      expect(none.toMap()[HomeWidgetKeys.lastPostAt], isEmpty);
    });
  });

  group('best time', () {
    test('no history leaves the hint empty', () {
      final snapshot = _build(records: const []);
      expect(snapshot.bestSlotLabel, isEmpty);
      expect(snapshot.bestSlotDetail, isEmpty);
      expect(snapshot.bestSlotConfident, isFalse);
    });

    test('two same-slot posts produce a low-confidence estimate', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'a',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 3, 20),
            reactions: 10,
          ),
          _record(
            id: 'b',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 10, 20),
            reactions: 12,
          ),
        ],
      );

      expect(snapshot.bestSlotLabel, isNotEmpty);
      expect(snapshot.bestSlotDetail, contains('posts'));
      expect(snapshot.bestSlotConfident, isFalse);
    });

    test('a scheduled post suppresses the hint', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'a',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 3, 20),
            reactions: 10,
          ),
          _record(
            id: 'b',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 10, 20),
            reactions: 12,
          ),
          _record(id: 'next', scheduledAt: DateTime(2026, 11, 14, 18)),
        ],
      );

      expect(snapshot.bestSlotLabel, isEmpty);
    });
  });

  group('offline counters', () {
    test('counts failed Stories', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'a',
            status: FacebookPostStatus.published,
            storyStatus: FacebookStoryStatus.failed,
          ),
          _record(
            id: 'b',
            status: FacebookPostStatus.published,
            storyStatus: FacebookStoryStatus.published,
          ),
        ],
      );
      expect(snapshot.storyFailedCount, 1);
      expect(snapshot.toMap()[HomeWidgetKeys.storyFailedCount], '1');
    });

    test('draft title collapses whitespace and truncates', () {
      final snapshot = _build(
        records: const [],
        draftCount: 1,
        draftTitle: '  Derby\n\npreview   for the weekend  ',
      );
      expect(snapshot.draftTitle, 'Derby preview for the weekend');

      final blank = _build(records: const [], draftCount: 1, draftTitle: '   ');
      expect(blank.draftTitle, isEmpty);
      final none = _build(records: const []);
      expect(none.draftCount, 0);
      expect(none.draftTitle, isEmpty);
    });

    test('week-to-date resets on Monday 00:00', () {
      // Sunday 15 Nov 2026, 23:00.
      final sunday = DateTime(2026, 11, 15, 23);
      final records = [
        _record(
          id: 'monday',
          status: FacebookPostStatus.published,
          timestamp: DateTime(2026, 11, 9, 0, 1),
        ),
        _record(
          id: 'sunday',
          status: FacebookPostStatus.published,
          timestamp: DateTime(2026, 11, 15, 12),
        ),
      ];
      final snapshot = _build(records: records, now: sunday);
      expect(snapshot.weekPostCount, 2);

      // Monday 16 Nov 00:30 — both belong to the previous week now.
      final monday = DateTime(2026, 11, 16, 0, 30);
      final next = _build(records: records, now: monday);
      expect(next.weekPostCount, 0);
    });

    test('quota average skips days with no activity', () {
      final snapshot = _build(
        records: const [],
        quotas: const [
          HomeWidgetQuota(
            modelId: 'gemini-2.5-flash',
            requestsToday: 40,
            budget: 500,
          ),
        ],
        quotaHistory: const {
          'gemini-2.5-flash': [40, 0, 60, 0, 20],
        },
      );
      expect(snapshot.quotaAverage, 40);
    });
  });

  group('pages_json', () {
    test('is empty when no Pages are connected', () {
      expect(_build(records: const []).pagesJson, '[]');
    });

    test('carries per-Page next-up and caps at five entries', () {
      final pages = [
        for (var i = 0; i < 7; i++) HomeWidgetPage(id: 'p$i', name: 'Page $i'),
      ];
      final snapshot = _build(
        records: [
          _record(
            id: 'p2next',
            pageId: 'p2',
            pageName: 'Page 2',
            scheduledAt: DateTime(2026, 11, 14, 18),
            snippet: 'Page two post',
          ),
        ],
        pages: pages,
      );
      final decoded = jsonDecode(snapshot.pagesJson) as List<dynamic>;
      expect(decoded, hasLength(5));
      expect(snapshot.pagesJson, contains('Page two post'));
      expect(
        snapshot.pagesJson.length,
        lessThanOrEqualTo(HomeWidgetSnapshotBuilder.maxPagesJsonChars),
      );
    });

    test('withholds per-Page snippets when the caption toggle is off', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'p1next',
            pageId: 'p1',
            scheduledAt: DateTime(2026, 11, 14, 18),
            snippet: 'Private caption',
          ),
        ],
        pages: const [HomeWidgetPage(id: 'p1', name: 'Page 1')],
        showSnippet: false,
      );
      expect(snapshot.pagesJson, isNot(contains('Private caption')));
    });
  });

  test('second row modes round-trip through the payload', () {
    for (final mode in HomeWidgetSecondRow.values) {
      final map = _build(records: const [], secondRow: mode).toMap();
      expect(map[HomeWidgetKeys.secondRowMode], mode.wireName);
      expect(
        HomeWidgetSecondRow.fromWire(map[HomeWidgetKeys.secondRowMode]),
        mode,
      );
    }
    expect(HomeWidgetSecondRow.fromWire('nonsense'), HomeWidgetSecondRow.quota);
  });
}
