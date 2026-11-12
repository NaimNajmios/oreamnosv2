import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_calendar_view_model.dart';
import 'package:oreamnos/ui/features/facebook/views/facebook_calendar_screen.dart';

FacebookPostRecord _record({
  required String id,
  required DateTime at,
  required bool scheduled,
}) => FacebookPostRecord(
  id: id,
  postId: 'post_$id',
  snippet: 'Post $id',
  message: 'Post $id',
  timestamp: at,
  hasImage: false,
  permalink: 'https://facebook.com/post_$id',
  status: scheduled
      ? FacebookPostStatus.scheduled
      : FacebookPostStatus.published,
  scheduledAt: scheduled ? at : null,
  pageId: 'page-1',
);

Widget _app(Map<DateTime, List<FacebookPostRecord>> grouped) {
  return ProviderScope(
    overrides: [facebookCalendarProvider.overrideWithValue(grouped)],
    child: const MaterialApp(home: FacebookCalendarScreen()),
  );
}

void main() {
  testWidgets('shows the month grid and day counts', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final today = facebookCalendarDayKey(now);
    final grouped = {
      today: [
        _record(
          id: 's1',
          at: now.add(const Duration(hours: 1)),
          scheduled: true,
        ),
        _record(
          id: 'p1',
          at: now.subtract(const Duration(hours: 1)),
          scheduled: false,
        ),
      ],
    };

    await tester.pumpWidget(_app(grouped));
    await tester.pumpAndSettle();

    expect(find.text('Content calendar'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);

    final day = tester.getSemantics(
      find.bySemanticsLabel(
        RegExp('${now.day} .*1 scheduled post, 1 published post'),
      ),
    );
    expect(day.label, contains('1 scheduled post'));
  });

  testWidgets('tapping a day opens its list', (tester) async {
    final now = DateTime.now();
    final today = facebookCalendarDayKey(now);
    final grouped = {
      today: [
        _record(
          id: 's1',
          at: now.add(const Duration(hours: 1)),
          scheduled: true,
        ),
      ],
    };

    await tester.pumpWidget(_app(grouped));
    await tester.pumpAndSettle();

    await tester.tap(find.text('${now.day}').first);
    await tester.pumpAndSettle();

    expect(find.text('1 post'), findsOneWidget);
    expect(find.byTooltip('Reschedule'), findsOneWidget);
    expect(find.byTooltip('Cancel post'), findsOneWidget);
  });
}
