import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/core/widgets/enhanced_loading_card.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'package:oreamnos/ui/core/widgets/input_clear_button.dart';
import 'package:oreamnos/ui/core/widgets/link_preview_card.dart';
import 'package:oreamnos/ui/core/widgets/success_overlay.dart';
import 'package:oreamnos/ui/core/widgets/swipeable_output_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Delight & Interaction Widgets', () {
    testWidgets('EnhancedLoadingCard shows plain-language stage copy', (
      tester,
    ) async {
      final cases = <LoadingStage, (String, String)>{
        LoadingStage.readingLink: (
          'Reading your link…',
          'Fetching the page and pulling out the article text.',
        ),
        LoadingStage.researching: (
          'Researching with AI…',
          'Gathering extra context to make the post sharper.',
        ),
        LoadingStage.writing: (
          'Writing your post…',
          'Turning the source into a ready-to-publish caption.',
        ),
        LoadingStage.polishing: (
          'Polishing your card…',
          'Tidying up the layout and text.',
        ),
      };

      for (final entry in cases.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: EnhancedLoadingCard(stage: entry.key)),
          ),
        );

        expect(find.byType(EnhancedLoadingCard), findsOneWidget);
        expect(find.byType(KickoffLoadingIndicator), findsOneWidget);
        expect(find.text(entry.value.$1), findsOneWidget);
        expect(find.text(entry.value.$2), findsOneWidget);
        // The internal design-system codename must never reach the UI, and
        // there is no longer a fabricated progress percentage.
        expect(find.textContaining('Serene Editorial'), findsNothing);
        expect(find.textContaining('%'), findsNothing);
      }
    });

    testWidgets('EnhancedLoadingCard notice replaces title and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedLoadingCard(
              stage: LoadingStage.writing,
              notice: 'Gemini rate-limited — retrying with Groq…',
            ),
          ),
        ),
      );

      expect(
        find.text('Gemini rate-limited — retrying with Groq…'),
        findsOneWidget,
      );
      expect(
        find.text('Turning the source into a ready-to-publish caption.'),
        findsNothing,
      );
      expect(
        find.text('Still working — this can take a moment.'),
        findsOneWidget,
      );
    });

    testWidgets('InputClearButton requires 2-step confirmation', (
      tester,
    ) async {
      bool cleared = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputClearButton(
              onClear: () => cleared = true,
              label: 'Clear All',
              confirmLabel: 'Really Clear?',
            ),
          ),
        ),
      );

      expect(find.text('Clear All'), findsOneWidget);
      expect(cleared, isFalse);

      // Step 1: Tap clear
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      expect(find.text('Really Clear?'), findsOneWidget);
      expect(cleared, isFalse);

      // Step 2: Confirm clear
      await tester.tap(find.text('Really Clear?'));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
    });

    testWidgets('LinkPreviewCard renders domain, url, and title', (
      tester,
    ) async {
      bool extractClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkPreviewCard(
              url: 'https://theathletic.com/football/123',
              title: 'Sensational Title',
              description: 'Article summary description',
              onExtract: () => extractClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('theathletic.com'), findsOneWidget);
      expect(find.text('Sensational Title'), findsOneWidget);
      expect(find.text('Article summary description'), findsOneWidget);
      expect(find.text('Extract'), findsOneWidget);

      await tester.tap(find.text('Extract'));
      await tester.pumpAndSettle();
      expect(extractClicked, isTrue);
    });

    testWidgets('SuccessOverlay renders and self-dismisses after animation', (
      tester,
    ) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuccessOverlay(onDismiss: () => dismissed = true),
          ),
        ),
      );

      expect(find.byType(SuccessOverlay), findsOneWidget);

      // Advance through the 1400ms animation
      await tester.pump(const Duration(milliseconds: 1500));
      expect(dismissed, isTrue);
    });

    testWidgets('SwipeableOutputCard renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SwipeableOutputCard(
                content: 'Great performance yesterday. #JDT #Football',
                child: Text('Curated Story Output'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SwipeableOutputCard), findsOneWidget);
      expect(find.text('Curated Story Output'), findsOneWidget);
    });
  });
}
