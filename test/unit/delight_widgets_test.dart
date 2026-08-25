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
    testWidgets('EnhancedLoadingCard renders extracting and generating stages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedLoadingCard(
              type: LoadingType.extracting,
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedLoadingCard), findsOneWidget);
      expect(find.byType(KickoffLoadingIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Extracting'), findsWidgets);
    });

    testWidgets('InputClearButton requires 2-step confirmation', (tester) async {
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

    testWidgets('LinkPreviewCard renders domain, url, and title', (tester) async {
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
      await tester.pump();
      expect(extractClicked, isTrue);
    });

    testWidgets('SuccessOverlay renders and self-dismisses after animation', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuccessOverlay(
              onDismiss: () => dismissed = true,
            ),
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
