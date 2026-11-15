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
  'android/app/src/main/res/layout/oreamnos_widget_small.xml',
  'android/app/src/main/res/layout/oreamnos_widget_wide.xml',
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

    for (final path in _layouts) {
      test('$path keeps every text at 9sp or larger', () {
        final sizes = [
          for (final match in RegExp(
            r'android:textSize="([0-9]+)sp"',
          ).allMatches(_read(path)))
            int.parse(match.group(1)!),
        ];
        expect(sizes, isNotEmpty);
        expect(
          sizes.where((size) => size < 9),
          isEmpty,
          reason:
              'The widget is not scrollable; sub-9sp type becomes unreadable '
              'at 200% font scale without saving a meaningful row.',
        );
      });
    }

    test('every tappable id resolves to a pending intent', () {
      final java = _read(_provider);
      final bound = {
        for (final match in RegExp(
          r'bindClick\(context,\s*views,\s*R\.id\.([a-z0-9_]+)',
          dotAll: true,
        ).allMatches(java))
          match.group(1)!,
      };

      // These are the interactive surfaces the provider promises.
      expect(
        bound,
        containsAll(<String>[
          'widget_root',
          'widget_snippet',
          'widget_compose',
          'widget_badge',
          'widget_quota',
          'widget_secondary',
        ]),
      );
    });

    test('pending intents are immutable with unique request codes', () {
      final java = _read(_provider);
      expect(java, contains('PendingIntent.FLAG_IMMUTABLE'));

      final codes = [
        for (final match in RegExp(
          r'private static final int (REQ_[A-Z_]+) = (\d+);',
        ).allMatches(java))
          match.group(2)!,
      ];
      expect(codes, isNotEmpty);
      expect(codes.toSet().length, codes.length);
    });

    test('provider maps every size class to its own layout', () {
      final java = _read(_provider);
      final referenced = {
        for (final match in RegExp(
          r'R\.layout\.(oreamnos_widget[a-z_]*)',
        ).allMatches(java))
          match.group(1)!,
      };
      expect(referenced, {
        'oreamnos_widget',
        'oreamnos_widget_compact',
        'oreamnos_widget_small',
        'oreamnos_widget_wide',
      });
    });

    test('widget info allows shrinking to a one-row strip', () {
      final info = _read(
        'android/app/src/main/res/xml/oreamnos_widget_info.xml',
      );
      expect(info, contains('android:minResizeWidth="110dp"'));
      expect(info, contains('android:minResizeHeight="40dp"'));
      expect(info, contains('android:resizeMode="horizontal|vertical"'));
      expect(info, contains('android:configure='));
    });
  });
}
