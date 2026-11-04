import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/ui/features/facebook/widgets/compose/facebook_compose_widgets.dart';

// 1x1 transparent PNG — smallest valid payload for Image.file in tests.
const _pixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMC'
    'AO+/p9sAAAAASUVORK5CYII=';

void main() {
  testWidgets('preview shows Page identity and message, no image initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostPreviewCard(
              pageName: 'Jamaica Football Talk',
              message: 'JDT seal the treble.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Jamaica Football Talk'), findsOneWidget);
    expect(find.text('JDT seal the treble.'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Your post text will appear here.'), findsNothing);
  });

  testWidgets('image preview appears only when a path is supplied', (
    tester,
  ) async {
    final dir = await tester.runAsync(() async {
      final created = await Directory.systemTemp.createTemp('oreamnos_preview');
      final file = File('${created.path}/card.png');
      await file.writeAsBytes(base64Decode(_pixelPng));
      return created;
    });
    final file = File('${dir!.path}/card.png');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostPreviewCard(
              pageName: 'Jamaica Football Talk',
              message: 'Card post',
              imagePath: file.path,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('4:5'), findsOneWidget);

    await tester.runAsync(() => dir.delete(recursive: true));
  });

  testWidgets('empty message falls back to the muted placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostPreviewCard(pageName: 'Page', message: '   '),
          ),
        ),
      ),
    );

    expect(find.text('Your post text will appear here.'), findsOneWidget);
  });
}
