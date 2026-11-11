import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget at a fixed phone size and text scale.
///
/// Use [scrollable] for tall screens; the default keeps the widget in a
/// bounded Scaffold so horizontal/vertical layout overflows are surfaced.
Future<void> pumpWithTextScale(
  WidgetTester tester,
  Widget widget, {
  double scale = 1.6,
  Size size = const Size(360, 640),
  bool scrollable = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final body = scrollable ? SingleChildScrollView(child: widget) : widget;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      home: Scaffold(body: body),
    ),
  );
  await tester.pump();
}

/// Asserts the last frame produced no layout overflow exception.
void expectNoOverflow(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
