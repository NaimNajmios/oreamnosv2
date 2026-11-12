import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/facebook_reminder_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeScheduler implements FacebookReminderScheduler {
  final scheduled = <({int id, String title, String body, DateTime at})>[];
  final cancelled = <int>[];
  bool permissionGranted = true;
  int permissionCalls = 0;

  @override
  Future<bool> requestPermission() async {
    permissionCalls++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String payload = 'facebook_scheduled_post',
  }) async {
    scheduled.add((id: id, title: title, body: body, at: at));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }
}

FacebookPostRecord _scheduled({
  required String id,
  required DateTime at,
  bool scheduled = true,
}) => FacebookPostRecord(
  id: id,
  postId: 'post_$id',
  snippet: 'Secret caption $id',
  message: 'Secret caption $id',
  timestamp: DateTime.now(),
  hasImage: false,
  permalink: '',
  status: scheduled
      ? FacebookPostStatus.scheduled
      : FacebookPostStatus.published,
  scheduledAt: scheduled ? at : null,
  pageId: 'page-1',
  pageName: 'Page',
);

void main() {
  late SharedPreferences prefs;
  late _FakeScheduler scheduler;
  late FacebookReminderService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    scheduler = _FakeScheduler();
    service = FacebookReminderService(prefs, scheduler);
  });

  test('schedules ten minutes before each future scheduled post', () async {
    final at = DateTime.now().add(const Duration(hours: 2));
    await service.sync([_scheduled(id: 'a', at: at)]);

    expect(scheduler.scheduled, hasLength(1));
    final entry = scheduler.scheduled.single;
    expect(entry.at, at.subtract(const Duration(minutes: 10)));
    expect(entry.title, 'Post goes live soon');
    expect(entry.body, isNot(contains('Secret caption')));
    expect(entry.body, contains('Scheduled for'));
  });

  test('skips past, due, and published records', () async {
    await service.sync([
      _scheduled(
        id: 'past',
        at: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      _scheduled(id: 'due', at: DateTime.now().add(const Duration(minutes: 3))),
      _scheduled(
        id: 'published',
        at: DateTime.now().add(const Duration(hours: 3)),
        scheduled: false,
      ),
    ]);

    expect(scheduler.scheduled, isEmpty);
  });

  test('disabled reminders make no platform calls', () async {
    await service.setEnabled(false);
    scheduler.scheduled.clear();
    scheduler.cancelled.clear();

    await service.sync([
      _scheduled(id: 'a', at: DateTime.now().add(const Duration(hours: 1))),
    ]);

    expect(scheduler.scheduled, isEmpty);
    expect(scheduler.cancelled, isEmpty);
  });

  test('removed or cancelled posts cancel their reminder', () async {
    await service.sync([
      _scheduled(id: 'a', at: DateTime.now().add(const Duration(hours: 1))),
    ]);
    final id = scheduler.scheduled.single.id;

    await service.sync(const []);

    expect(scheduler.cancelled, [id]);
  });

  test('reuses the same notification id across syncs', () async {
    final at = DateTime.now().add(const Duration(hours: 1));
    await service.sync([_scheduled(id: 'a', at: at)]);
    await service.sync([_scheduled(id: 'a', at: at)]);

    expect(scheduler.scheduled.map((s) => s.id).toSet(), hasLength(1));
    expect(scheduler.cancelled, isEmpty);
  });

  test('every scheduled post gets a distinct id', () async {
    await service.sync([
      _scheduled(id: 'a', at: DateTime.now().add(const Duration(hours: 1))),
      _scheduled(id: 'b', at: DateTime.now().add(const Duration(hours: 2))),
    ]);

    final ids = scheduler.scheduled.map((s) => s.id).toList();
    expect(ids, hasLength(2));
    expect(ids.toSet(), hasLength(2));
  });

  test('denied permission skips scheduling without throwing', () async {
    scheduler.permissionGranted = false;

    await service.sync([
      _scheduled(id: 'a', at: DateTime.now().add(const Duration(hours: 1))),
    ]);

    expect(scheduler.permissionCalls, 1);
    expect(scheduler.scheduled, isEmpty);
  });

  test('turning reminders off cancels persisted ids', () async {
    await service.sync([
      _scheduled(id: 'a', at: DateTime.now().add(const Duration(hours: 1))),
    ]);
    final id = scheduler.scheduled.single.id;

    await service.setEnabled(false);

    expect(scheduler.cancelled, contains(id));
    expect(service.enabled, isFalse);
  });
}
