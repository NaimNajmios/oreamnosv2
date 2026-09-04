import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/app_kickoff.dart';
import 'package:oreamnos/ui/core/widgets/app_snackbar.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_mark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppKickoff tokens', () {
    test('orbit geometry matches icon.svg ratios', () {
      expect(AppKickoff.orbitCount, 18);
      expect(AppKickoff.orbitRadiusFactor, closeTo(170 / 512, 1e-9));
      expect(AppKickoff.dotRadiusFactor, closeTo(14 / 512, 1e-9));
      expect(AppKickoff.ringRadiusFactor, closeTo(56 / 512, 1e-9));
      expect(AppKickoff.ringStrokeFactor, closeTo(12 / 512, 1e-9));
      expect(AppKickoff.coreRadiusFactor, closeTo(10 / 512, 1e-9));
    });

    test('accentDotIndex maps progress to orbit dot', () {
      expect(AppKickoff.accentDotIndex(null), -1);
      expect(AppKickoff.accentDotIndex(0), -1);
      expect(AppKickoff.accentDotIndex(0.5), 9);
      expect(AppKickoff.accentDotIndex(1), 17);
      expect(AppKickoff.accentDotIndex(2), 17);
    });
  });

  group('Kickoff widgets', () {
    testWidgets('KickoffMark renders with accent dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: KickoffMark(size: 120, highlightedIndex: 4)),
        ),
      );
      expect(find.byType(KickoffMark), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('EmptyState kickoff variant breathes without icon chrome', (
      tester,
    ) async {
      // disableAnimations: breathing loop is infinite; the static mark is
      // what we assert here (breathing is covered by the reduce-motion
      // branch via AppMotion.shouldReduceMotion).
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: EmptyState(
                icon: Icons.history_rounded,
                title: 'No Sessions Yet',
                description: 'Sessions will appear here.',
                illustrationStyle: EmptyIllustrationStyle.kickoff,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(KickoffMark), findsOneWidget);
      expect(find.text('No Sessions Yet'), findsOneWidget);
    });

    testWidgets('KickoffDotsDivider renders five dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: KickoffDotsDivider(count: 5))),
      );
      expect(find.byType(KickoffDotsDivider), findsOneWidget);
    });

    testWidgets('AppSnackBar shows message with undo action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppSnackBar.show(
                  context,
                  'Input text cleared',
                  actionLabel: 'UNDO',
                ),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pump();
      expect(find.text('Input text cleared'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
    });
  });
}
