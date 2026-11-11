import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_banner.dart';

import '../helpers/a11y_helpers.dart';

void main() {
  testWidgets('offline banner renders at large text without overflow', (
    tester,
  ) async {
    await pumpWithTextScale(
      tester,
      FacebookConnectionBanner(offline: true, expired: false, onRetry: () {}),
      scale: 2.0,
      size: const Size(320, 640),
      scrollable: true,
    );

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expectNoOverflow(tester);
  });

  testWidgets('expired banner offers reconnect and is a live region', (
    tester,
  ) async {
    await pumpWithTextScale(
      tester,
      FacebookConnectionBanner(
        offline: false,
        expired: true,
        onReconnect: () {},
      ),
      scale: 1.6,
      scrollable: true,
    );

    expect(find.text('Reconnect'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byType(FacebookConnectionBanner),
    );
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
    expectNoOverflow(tester);
  });

  testWidgets('banner is empty when the connection is healthy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FacebookConnectionBanner(offline: false, expired: false),
        ),
      ),
    );

    expect(find.byType(Text), findsNothing);
  });
}
