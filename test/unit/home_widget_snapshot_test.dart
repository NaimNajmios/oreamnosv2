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

/// Gemini with a budget — the only provider the app can honestly gauge.
HomeWidgetQuota _gemini({
  String modelId = '2.5-flash',
  int requestsToday = 312,
  int? budget = 500,
  int? average = 40,
  DateTime? resetAt,
}) => HomeWidgetQuota(
  providerId: 'gemini',
  displayName: 'Gemini',
  modelId: modelId,
  requestsToday: requestsToday,
  budget: budget,
  average: average,
  resetAt: resetAt,
);

/// Count-only provider: no budget, like every non-Gemini provider.
HomeWidgetQuota _countOnly({
  required String providerId,
  required String displayName,
  int requestsToday = 12,
}) => HomeWidgetQuota(
  providerId: providerId,
  displayName: displayName,
  modelId: '',
  requestsToday: requestsToday,
);

HomeWidgetSnapshot _build({
  required List<FacebookPostRecord> records,
  List<HomeWidgetQuota> quotas = const [],
  String pageName = 'Football Malaysia',
  bool pageConnected = true,
  bool pageExpired = false,
  int draftCount = 0,
  String activeProvider = 'gemini',
  String fallbackProvider = 'groq',
  DateTime? now,
  List<HomeWidgetPage> pages = const [],
  String draftTitle = '',
  DateTime? draftUpdatedAt,
  bool showSnippet = true,
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
    activeProvider: activeProvider,
    fallbackProvider: fallbackProvider,
    pages: pages,
    draftTitle: draftTitle,
    draftUpdatedAt: draftUpdatedAt,
    showSnippet: showSnippet,
  );
}

List<dynamic> _quotaEntries(HomeWidgetSnapshot snapshot) =>
    jsonDecode(snapshot.quotaJson) as List<dynamic>;

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
    test('carries every provider, with a budget only where one exists', () {
      final snapshot = _build(
        records: const [],
        quotas: [
          _gemini(resetAt: DateTime(2026, 11, 14, 18)),
          _countOnly(providerId: 'groq', displayName: 'Groq'),
        ],
      );
      final entries = _quotaEntries(snapshot);
      expect(entries, hasLength(2));

      final gemini = entries.first as Map<String, dynamic>;
      expect(gemini['p'], 'gemini');
      expect(gemini['n'], 'Gemini');
      expect(gemini['u'], 312);
      expect(gemini['b'], 500);
      expect(gemini['pc'], 62);
      expect(gemini['s'], 0);
      expect(gemini['a'], 40);
      expect(gemini['r'], DateTime(2026, 11, 14, 18).millisecondsSinceEpoch);

      final groq = entries.last as Map<String, dynamic>;
      expect(groq['p'], 'groq');
      expect(groq['u'], 12);
      // No budget means no ring, no percentage and no severity on the wire.
      expect(groq.containsKey('b'), isFalse);
      expect(groq.containsKey('pc'), isFalse);
      expect(groq.containsKey('s'), isFalse);
    });

    test('severity warns at 80% and trips at the budget', () {
      final warn = _gemini(requestsToday: 400, budget: 500);
      final over = _gemini(requestsToday: 500, budget: 500);
      final ok = _gemini(requestsToday: 399, budget: 500);

      expect(ok.severity(0.8), 0);
      expect(warn.severity(0.8), 1);
      expect(over.severity(0.8), 2);
      // No real budget: never a severity.
      expect(
        _countOnly(providerId: 'groq', displayName: 'Groq').severity(0.8),
        0,
      );
    });

    test('percentage clamps at 100 when the budget is exceeded', () {
      final over = _gemini(requestsToday: 900, budget: 500);
      final encoded = over.toJson(0.8);
      expect(encoded['pc'], 100);
      expect(encoded['s'], 2);
    });

    test('no quota activity still ships a parseable empty array', () {
      final snapshot = _build(records: const []);
      expect(snapshot.quotaJson, '[]');
      expect(_quotaEntries(snapshot), isEmpty);
      expect(snapshot.quotaResetAt, isNull);
    });

    test('quota reset is the earliest future reset with a budget', () {
      final early = DateTime(2026, 11, 14, 15);
      final late = DateTime(2026, 11, 14, 20);
      final snapshot = _build(
        records: const [],
        quotas: [
          _gemini(resetAt: late),
          HomeWidgetQuota(
            providerId: 'groq',
            displayName: 'Groq',
            modelId: '',
            requestsToday: 5,
            resetAt: early,
          ),
        ],
      );

      // Groq has no budget, so its reset cannot drive a quota alarm.
      expect(snapshot.quotaResetAt, late);
    });

    test('encodes at most four providers so the payload cannot overflow', () {
      final snapshot = _build(
        records: const [],
        quotas: [
          _gemini(),
          _countOnly(providerId: 'groq', displayName: 'Groq'),
          _countOnly(providerId: 'openrouter', displayName: 'OpenRouter'),
          _countOnly(providerId: 'cerebras', displayName: 'Cerebras'),
          _countOnly(providerId: 'extra', displayName: 'Extra'),
        ],
      );

      expect(_quotaEntries(snapshot), hasLength(4));
      expect(
        snapshot.quotaJson.length,
        lessThanOrEqualTo(HomeWidgetSnapshotBuilder.maxQuotaJsonChars),
      );
    });

    test('exposes the active and fallback provider for the default pair', () {
      final snapshot = _build(
        records: const [],
        activeProvider: 'openrouter',
        fallbackProvider: 'cerebras',
      );
      final map = snapshot.toMap();
      expect(map[HomeWidgetKeys.activeProvider], 'openrouter');
      expect(map[HomeWidgetKeys.fallbackProvider], 'cerebras');
    });
  });

  test('payload only contains whitelisted string keys', () {
    final snapshot = _build(
      records: [_record(id: 'x', scheduledAt: DateTime(2026, 11, 14, 15))],
      quotas: [_gemini(requestsToday: 10)],
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
      if (entry.key == HomeWidgetKeys.pagesJson ||
          entry.key == HomeWidgetKeys.quotaJson) {
        continue;
      }
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
    expect(
      map[HomeWidgetKeys.quotaJson]!.length,
      lessThanOrEqualTo(HomeWidgetSnapshotBuilder.maxQuotaJsonChars),
    );

    // The retired combined widget's setting must not linger.
    expect(map.containsKey('second_row_mode'), isFalse);
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
      quotas: [_gemini(requestsToday: 1, resetAt: at)],
      now: at,
    ).toMap();

    expect(map[HomeWidgetKeys.nextAt], '${at.millisecondsSinceEpoch}');
    // quota_reset_at is deliberately not in the payload: the reset instant
    // already travels inside quota_json.
    expect(map.containsKey('quota_reset_at'), isFalse);
    final entry =
        _quotaEntries(
              _build(
                records: const [],
                quotas: [_gemini(requestsToday: 1, resetAt: at)],
                now: at,
              ),
            ).first
            as Map<String, dynamic>;
    expect(entry['r'], at.millisecondsSinceEpoch);
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

    test('week totals add up this week only', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'this-week',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 13, 9),
            reactions: 10,
            comments: 2,
            shares: 1,
          ),
          _record(
            id: 'also-this-week',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 12, 9),
            reactions: 5,
            comments: 1,
          ),
          _record(
            id: 'last-week',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 2, 9),
            reactions: 100,
          ),
        ],
        now: DateTime(2026, 11, 14, 12),
      );

      expect(snapshot.weekReactions, 15);
      expect(snapshot.weekComments, 3);
      expect(snapshot.weekShares, 1);
      expect(snapshot.weekPostCount, 2);
      expect(snapshot.toMap()[HomeWidgetKeys.weekReactions], '15');
    });

    test('a week without posts reports zeros, not last week', () {
      final snapshot = _build(
        records: [
          _record(
            id: 'last-week',
            status: FacebookPostStatus.published,
            timestamp: DateTime(2026, 11, 2, 9),
            reactions: 100,
          ),
        ],
        now: DateTime(2026, 11, 14, 12),
      );

      expect(snapshot.weekReactions, 0);
      expect(snapshot.weekComments, 0);
      expect(snapshot.weekShares, 0);
      expect(snapshot.weekPostCount, 0);
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
      expect(none.draftUpdatedAt, isNull);
    });

    test('draft timestamp survives as an epoch string', () {
      final at = DateTime(2026, 11, 14, 10, 5);
      final map = _build(
        records: const [],
        draftCount: 1,
        draftUpdatedAt: at,
      ).toMap();
      expect(
        map[HomeWidgetKeys.draftUpdatedAt],
        '${at.millisecondsSinceEpoch}',
      );
      expect(
        _build(records: const []).toMap()[HomeWidgetKeys.draftUpdatedAt],
        isEmpty,
      );
    });

    test('week-to-date resets on Monday 00:00', () {
      // Sunday 15 Nov 2026, 23:00.
      final sunday = DateTime(2026, 11, 15, 23);
      final records = [
        _record(
          id: 'monday',
          status: FacebookPostStatus.published,
          timestamp: DateTime(2026, 11, 9, 0, 1),
          reactions: 3,
        ),
        _record(
          id: 'sunday',
          status: FacebookPostStatus.published,
          timestamp: DateTime(2026, 11, 15, 12),
          reactions: 4,
        ),
      ];
      final snapshot = _build(records: records, now: sunday);
      expect(snapshot.weekPostCount, 2);
      expect(snapshot.weekReactions, 7);

      // Monday 16 Nov 00:30 — both belong to the previous week now.
      final monday = DateTime(2026, 11, 16, 0, 30);
      final next = _build(records: records, now: monday);
      expect(next.weekPostCount, 0);
      expect(next.weekReactions, 0);
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
}
