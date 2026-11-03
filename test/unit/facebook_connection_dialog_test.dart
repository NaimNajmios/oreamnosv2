import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression: `TextField` asserts `!obscureText || maxLines == 1`, so an
/// obscured multiline input crashed the Facebook connection dialog.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    getIt.allowReassignment = true;
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('AppInput forces single-line when obscured', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppInput(
            controller: controller,
            label: 'Token',
            maxLines: 4,
            minLines: 2,
            obscureText: true,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(field.maxLines, 1);
    expect(field.minLines, isNull);
  });

  testWidgets('AppInput keeps multiline when not obscured', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppInput(
            controller: controller,
            label: 'Body',
            maxLines: 6,
            minLines: 3,
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
    expect(field.maxLines, 6);
    expect(field.minLines, 3);
  });

  testWidgets(
    'connection dialog renders obscured, revealing expands to 2 lines',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: FacebookConnectionDialog())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.maxLines, 1);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
      expect(field.maxLines, 2);
    },
  );

  // Re-boot DI with a persisted Page so the dialog shows all 3 actions.
  Future<void> bootConnected() async {
    SharedPreferences.setMockInitialValues({
      'facebook_page_id': '123456',
      'facebook_page_name': 'Trace Football',
    });
    await getIt.reset();
    await configureDependencies();
    getIt.allowReassignment = true;
  }

  testWidgets('actions do not overflow on a 360dp phone (3 buttons)', (
    tester,
  ) async {
    // The previous Row overflowed by 18px with Disconnect + Cancel + Save.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await bootConnected();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: FacebookConnectionDialog())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Disconnect'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Test & Save'), findsOneWidget);
  });

  testWidgets('actions wrap instead of overflowing at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await bootConnected();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: FacebookConnectionDialog())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final disconnectY = tester.getCenter(find.text('Disconnect')).dy;
    final cancelY = tester.getCenter(find.text('Cancel')).dy;
    expect(
      cancelY,
      greaterThan(disconnectY),
      reason: 'OverflowBar should stack the actions on separate rows',
    );
  });
}
