import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/ui/core/dialogs/rate_limit_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDialog(
    WidgetTester tester, {
    AiProvider? fallback,
    String? waitHint,
    bool fallbackHasKey = true,
    bool isRetrying = false,
    VoidCallback? onRetry,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => RateLimitDialog.show(
                context,
                suggestedFallbackProvider: fallback,
                currentProviderName: 'Gemini',
                onRetryWithFallback: onRetry,
                waitTimeMessage: waitHint,
                fallbackHasKey: fallbackHasKey,
                isRetrying: isRetrying,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Screens with an infinite spinner (retrying state) never settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  group('RateLimitDialog', () {
    testWidgets('fallback variant fits 360px screen, no overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDialog(
        tester,
        fallback: AiProvider.groq,
        waitHint: 'Retry in 11s',
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Rate Limit Exceeded'), findsOneWidget);
      expect(find.textContaining('Groq'), findsWidgets);
      expect(find.text('Retry in 11s'), findsOneWidget);
      expect(find.text('Retry with Groq'), findsOneWidget);
      expect(find.text('Stay on Gemini'), findsOneWidget);
    });

    testWidgets('retry invokes callback and dismisses', (tester) async {
      var retried = false;
      await pumpDialog(
        tester,
        fallback: AiProvider.groq,
        onRetry: () => retried = true,
      );

      await tester.tap(find.text('Retry with Groq'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
      expect(find.text('Rate Limit Exceeded'), findsNothing);
    });

    testWidgets('missing fallback key disables retry with hint', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        fallback: AiProvider.groq,
        fallbackHasKey: false,
        onRetry: () => fail('must not fire without a key'),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Add your Groq key'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('retrying state shows spinner and disables actions', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        fallback: AiProvider.groq,
        isRetrying: true,
        settle: false,
      );

      expect(find.text('Retrying…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Stay on Gemini'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('no-fallback variant shows single acknowledgement', (
      tester,
    ) async {
      await pumpDialog(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Got it'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
