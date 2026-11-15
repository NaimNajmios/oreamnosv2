/// Guard rail for the RemoteViews contract.
///
/// The launcher inflates app-widget layouts through a filter that rejects every
/// view class without the `@RemoteView` annotation
/// (`RemoteViews.java`: `clazz -> clazz.isAnnotationPresent(RemoteView.class)`).
/// A rejected tag fails at inflation time and the user sees "Problem loading
/// widget" — while `flutter build` stays perfectly green, which is how `<Space>`
/// reached a release build once already.
///
/// `<Space>` and a plain `<View>` are the classic traps.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Classes annotated `@RemoteView` in AOSP that an app widget may use.
const _remoteViewClasses = <String>{
  'AdapterViewFlipper',
  'AnalogClock',
  'Button',
  'Chronometer',
  'FrameLayout',
  'GridLayout',
  'GridView',
  'ImageButton',
  'ImageView',
  'LinearLayout',
  'ListView',
  'ProgressBar',
  'RelativeLayout',
  'StackView',
  'TextClock',
  'TextView',
  'ViewFlipper',
};

const _layouts = <String>[
  'android/app/src/main/res/layout/oreamnos_widget.xml',
  'android/app/src/main/res/layout/oreamnos_widget_compact.xml',
];

const _provider =
    'android/app/src/main/java/com/najmi/oreamnos/widget/OreamnosWidgetProvider.java';

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file.readAsStringSync();
}

/// Element names only. Closing tags, comments and the `<?xml` prologue start
/// with a non-letter, so they never match.
Set<String> _elementTags(String xml) => {
  for (final match in RegExp(r'<([A-Za-z][A-Za-z0-9._]*)').allMatches(xml))
    match.group(1)!,
};

Set<String> _viewIds(String xml) => {
  for (final match in RegExp(r'@\+id/([a-z0-9_]+)').allMatches(xml))
    match.group(1)!,
};

void main() {
  group('widget layouts are RemoteViews-safe', () {
    for (final path in _layouts) {
      test('$path only uses @RemoteView classes', () {
        final rejected = _elementTags(_read(path))
            .difference(_remoteViewClasses);

        expect(
          rejected,
          isEmpty,
          reason:
              'The launcher would throw "Class not allowed to be inflated" and '
              'show "Problem loading widget". Rewrite these as FrameLayout or '
              'another @RemoteView class: ${rejected.join(', ')}',
        );
      });

      test('$path avoids the Space/View trap', () {
        final tags = _elementTags(_read(path));

        // Proves the parser actually saw elements; otherwise the negative
        // assertions below would pass on an empty set.
        expect(tags, contains('LinearLayout'));
        expect(tags, isNot(contains('Space')));
        expect(tags, isNot(contains('View')));
      });
    }

    test('both layouts expose every id the provider binds', () {
      final javaIds = {
        for (final match in RegExp(
          r'R\.id\.([a-z0-9_]+)',
        ).allMatches(_read(_provider)))
          match.group(1)!,
      };
      expect(javaIds, isNotEmpty);

      for (final path in _layouts) {
        final ids = _viewIds(_read(path));
        expect(
          javaIds.difference(ids),
          isEmpty,
          reason: '$path is missing ids the provider sets',
        );
      }
    });

    test('both layouts share the same view ids', () {
      // The provider renders both layouts with one code path, so a missing id
      // in either file is a NullPointerException waiting to happen.
      final sets = [for (final path in _layouts) _viewIds(_read(path))];

      expect(sets.first, sets.last);
    });
  });
}
