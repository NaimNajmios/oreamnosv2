import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_post_actions_sheet.dart';

FacebookPostRecord _record({required bool storyOnly}) => FacebookPostRecord(
  id: 'r1',
  postId: 'post_1',
  snippet: 'Story title',
  message: 'Story title',
  timestamp: DateTime(2026, 11, 12),
  hasImage: true,
  permalink: storyOnly ? '' : 'https://facebook.com/post_1',
  status: FacebookPostStatus.published,
  pageId: 'page-1',
  isStoryOnly: storyOnly,
);

void main() {
  testWidgets('Story-only records hide feed actions and explain why', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => FacebookPostActionsSheet.show(
                context,
                _record(storyOnly: true),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Story only'), findsOneWidget);
    expect(find.text('This Story has no feed post to open.'), findsOneWidget);
    expect(find.text('Open post'), findsNothing);
    expect(find.text('Copy link'), findsNothing);
    expect(find.text('Copy caption'), findsOneWidget);
  });

  testWidgets('feed posts keep Open and Copy link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => FacebookPostActionsSheet.show(
                context,
                _record(storyOnly: false),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Open post'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Story only'), findsNothing);
  });
}
