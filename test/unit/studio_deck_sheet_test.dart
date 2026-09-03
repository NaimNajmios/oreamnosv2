import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/studio_deck_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _setupDi() async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  const storage = FlutterSecureStorage();
  final prefService = PreferencesService(prefs: prefs, secureStorage: storage);

  await getIt.reset();
  await configureDependencies();
  getIt.allowReassignment = true;
  getIt.registerLazySingleton<PreferencesService>(() => prefService);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_setupDi);

  testWidgets('StudioDeckSheet renders fields + MISSING chip', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SizedBox(height: 800, child: StudioDeckSheet())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default template is socialPost — Account Name / Username / Post Content.
    expect(find.text('Studio Deck'), findsOneWidget);
    expect(find.text('Account Name *'), findsOneWidget);
    expect(find.text('Post Content *'), findsOneWidget);
    // Template switcher present (horizontal list — scroll into view).
    final horizontal = find
        .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.horizontal)
        .first;
    await tester.scrollUntilVisible(
      find.text('Breaking News'),
      300,
      scrollable: horizontal,
    );
    expect(find.text('Breaking News'), findsOneWidget);
    expect(find.text('AI Rewrite All'), findsOneWidget);
  });

  testWidgets('StudioDeckSheet shows fields after template switch', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SizedBox(height: 800, child: StudioDeckSheet())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final horizontal = find
        .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.horizontal)
        .first;
    await tester.scrollUntilVisible(
      find.text('Breaking News'),
      300,
      scrollable: horizontal,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Breaking News'));
    await tester.pumpAndSettle();

    expect(find.text('Headline *'), findsOneWidget);
    expect(find.textContaining('MISSING'), findsWidgets);
  });

  test('updateCardField writes headline on sealed model', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cardGeneratorViewModelProvider.notifier);
    notifier.updateHeadline('JDT Menang');
    container
        .read(cardGeneratorViewModelProvider.notifier)
        .updateCardField('headline', 'JDT Menang 3-0');
    final state = container.read(cardGeneratorViewModelProvider);
    expect(state.cardData, isA<CardData>());
    expect(state.cardData!.headline, contains('JDT'));
  });
}
