import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/domain/models/facebook_post_insights.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    getIt.allowReassignment = true;
  });

  tearDown(() {
    getIt.reset();
  });

  Future<FacebookHistoryService> makeService() async {
    final prefs = await SharedPreferences.getInstance();
    return FacebookHistoryService(prefs);
  }

  group('FacebookHistoryService', () {
    test('recordPublish caps at 50, newest first', () async {
      final service = await makeService();
      for (int i = 1; i <= 51; i++) {
        await service.recordPublish(
          postId: 'p$i',
          message: 'Post $i #FAM',
          permalink: 'https://www.facebook.com/post$i',
          hasImage: false,
        );
      }
      final records = service.records;
      expect(records.length, 50);
      expect(records.first.postId, 'p51');
      expect(records[1].postId, 'p50');
      expect(records.last.postId, 'p2', reason: 'p1 evicted first');
    });

    test('snippets truncate and survive a restart (prefs JSON)', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = FacebookHistoryService(prefs);
      final long = 'Pure text line 1\n' * 20;
      await service.recordPublish(
        postId: 'p1',
        message: long,
        permalink: 'https://www.facebook.com/p1',
        hasImage: false,
      );
      expect(service.records.first.snippet.length, lessThanOrEqualTo(141));
      expect(service.records.first.snippet, startsWith('Pure text line 1'));

      // Fresh instance on the same prefs = restart parity.
      final reloaded = FacebookHistoryService(prefs);
      expect(reloaded.records.length, 1);
      expect(reloaded.records.first.id, service.records.first.id);
    });

    test('empty message falls back to a descriptive snippet', () async {
      final service = await makeService();
      final record = await service.recordPublish(
        postId: 'p1',
        message: '   ',
        permalink: 'https://www.facebook.com/p1',
        hasImage: true,
      );
      expect(record.snippet, 'Card post');
      expect(record.hasImage, isTrue);
    });

    test(
      'scheduled records persist status + time and removeByPostId',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final service = FacebookHistoryService(prefs);
        final at = DateTime.now().add(const Duration(hours: 2));
        await service.recordPublish(
          postId: 'sched_1',
          message: 'Later',
          permalink: '',
          hasImage: false,
          status: FacebookPostStatus.scheduled,
          scheduledAt: at,
          pageId: '123',
          pageName: 'Oreamnos FC',
        );
        final record = service.records.single;
        expect(record.isScheduled, isTrue);
        expect(record.pageName, 'Oreamnos FC');
        expect(record.scheduledAt!.toUtc(), at.toUtc());

        final reloaded = FacebookHistoryService(prefs);
        expect(reloaded.records.single.isScheduled, isTrue);

        await reloaded.removeByPostId('sched_1');
        expect(reloaded.records, isEmpty);
        expect(FacebookHistoryService(prefs).records, isEmpty);
      },
    );

    test('setInsights caches metrics and survives a restart', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = FacebookHistoryService(prefs);
      final record = await service.recordPublish(
        postId: 'p1',
        message: 'One',
        permalink: 'https://www.facebook.com/p1',
        hasImage: false,
      );
      final at = DateTime.now();
      await service.setInsights(
        record.id,
        FacebookPostInsights(
          impressions: 1200,
          reactions: 84,
          clicks: 31,
          fetchedAt: at,
        ),
      );

      final cached = service.records.single;
      expect(cached.impressions, 1200);
      expect(cached.reactions, 84);
      expect(cached.clicks, 31);
      expect(cached.hasInsights, isTrue);

      final reloaded = FacebookHistoryService(prefs);
      expect(reloaded.records.single.impressions, 1200);
      expect(reloaded.records.single.insightsFetchedAt, isNotNull);
    });

    test('partial insights keep missing metrics null', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = FacebookHistoryService(prefs);
      final record = await service.recordPublish(
        postId: 'p1',
        message: 'One',
        permalink: 'https://www.facebook.com/p1',
        hasImage: false,
      );
      await service.setInsights(
        record.id,
        FacebookPostInsights(impressions: 7, fetchedAt: DateTime.now()),
      );
      final cached = service.records.single;
      expect(cached.impressions, 7);
      expect(cached.reactions, isNull);
      expect(cached.clicks, isNull);
      expect(cached.hasInsights, isTrue);
    });

    test('remove and clear update state and persist', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = FacebookHistoryService(prefs);
      await service.recordPublish(
        postId: 'p1',
        message: 'One',
        permalink: 'https://www.facebook.com/p1',
        hasImage: false,
      );
      final second = await service.recordPublish(
        postId: 'p2',
        message: 'Two',
        permalink: 'https://www.facebook.com/p2',
        hasImage: false,
      );

      var notified = 0;
      service.addListener((_) => notified++);

      await service.remove(second.id);
      expect(service.records.single.postId, 'p1');
      await service.clear();
      expect(service.records, isEmpty);
      expect(notified, 2, reason: 'listener fired once per mutation');

      final reloaded = FacebookHistoryService(prefs);
      expect(reloaded.records, isEmpty);
    });
  });

  group('facebookHistoryProvider', () {
    test('exposes the service-backed records through Riverpod', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final initial = container.read(facebookHistoryProvider);
      expect(initial, isEmpty);

      final notifier = container.read(facebookHistoryProvider.notifier);
      await notifier.remove('anything'); // no-op removes still notify empty
      final after = container.read(facebookHistoryProvider);
      expect(after, isEmpty);
    });
  });
}
