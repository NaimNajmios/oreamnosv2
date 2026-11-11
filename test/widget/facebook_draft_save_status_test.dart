import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_draft_save_status.dart';

import '../helpers/a11y_helpers.dart';

Widget _wrap(FacebookDraftSaveStatus status) {
  return MaterialApp(home: Scaffold(body: status));
}

void main() {
  testWidgets('idle renders nothing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FacebookDraftSaveStatus(
          state: FacebookDraftSaveState.idle,
          savedAt: null,
          onRetry: () {},
        ),
      ),
    );

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('pending and saving communicate progress as a live region', (
    tester,
  ) async {
    await pumpWithTextScale(
      tester,
      FacebookDraftSaveStatus(
        state: FacebookDraftSaveState.pending,
        savedAt: null,
        onRetry: () {},
      ),
      scale: 1.6,
    );
    expect(find.text('Unsaved changes'), findsOneWidget);
    expectNoOverflow(tester);

    await pumpWithTextScale(
      tester,
      FacebookDraftSaveStatus(
        state: FacebookDraftSaveState.saving,
        savedAt: null,
        onRetry: () {},
      ),
      scale: 1.6,
    );
    expect(find.text('Saving draft…'), findsOneWidget);
    final semantics = tester.getSemantics(find.byType(FacebookDraftSaveStatus));
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
    expectNoOverflow(tester);
  });

  testWidgets('saved shows the save time', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FacebookDraftSaveStatus(
          state: FacebookDraftSaveState.saved,
          savedAt: DateTime(2026, 11, 11, 9, 5),
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Draft saved · 09:05'), findsOneWidget);
  });

  testWidgets('failed offers a 48dp retry that fires the callback', (
    tester,
  ) async {
    var retries = 0;
    await pumpWithTextScale(
      tester,
      FacebookDraftSaveStatus(
        state: FacebookDraftSaveState.failed,
        savedAt: null,
        onRetry: () => retries++,
      ),
      scale: 1.6,
    );

    expect(find.text("Couldn't save draft"), findsOneWidget);
    final retry = find.widgetWithText(TextButton, 'Retry');
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    await tester.tap(retry);
    expect(retries, 1);
    expectNoOverflow(tester);
  });
}
