/// Guard rail for the RemoteViews contract of the five home-screen widgets.
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

/// Ids every widget declares so the shared version gate, surface and footer are
/// one code path in `BaseOreamnosWidget`.
const _commonIds = <String>{
  'widget_root',
  'widget_body',
  'widget_notice',
  'widget_updated',
};

class _WidgetSpec {
  const _WidgetSpec({
    required this.name,
    required this.provider,
    required this.layouts,
    required this.info,
    this.configurable = false,
  });

  final String name;

  /// Receiver class file, relative to the repo root.
  final String provider;

  /// Layout files, relative to the repo root. One per size class.
  final List<String> layouts;

  /// The `*_widget_info.xml` that declares the placement contract.
  final String info;

  /// Only Next up and AI quota have something to configure.
  final bool configurable;
}

const _widgetRoot = 'android/app/src/main/res/layout';
const _providerRoot = 'android/app/src/main/java/com/najmi/oreamnos/widget';
const _xmlRoot = 'android/app/src/main/res/xml';

const _widgets = <_WidgetSpec>[
  _WidgetSpec(
    name: 'Next up',
    provider: '$_providerRoot/OreamnosWidgetProvider.java',
    layouts: [
      '$_widgetRoot/oreamnos_widget.xml',
      '$_widgetRoot/oreamnos_widget_compact.xml',
      '$_widgetRoot/oreamnos_widget_small.xml',
      '$_widgetRoot/oreamnos_widget_wide.xml',
    ],
    info: '$_xmlRoot/oreamnos_widget_info.xml',
    configurable: true,
  ),
  _WidgetSpec(
    name: 'AI quota',
    provider: '$_providerRoot/OreamnosQuotaWidgetProvider.java',
    layouts: [
      '$_widgetRoot/oreamnos_quota_widget.xml',
      '$_widgetRoot/oreamnos_quota_widget_card.xml',
      '$_widgetRoot/oreamnos_quota_widget_banner.xml',
      '$_widgetRoot/oreamnos_quota_widget_square.xml',
    ],
    info: '$_xmlRoot/oreamnos_quota_widget_info.xml',
    configurable: true,
  ),
  _WidgetSpec(
    name: 'Engagement',
    provider: '$_providerRoot/OreamnosEngagementWidgetProvider.java',
    layouts: [
      '$_widgetRoot/oreamnos_engagement_widget.xml',
      '$_widgetRoot/oreamnos_engagement_widget_grid.xml',
      '$_widgetRoot/oreamnos_engagement_widget_row.xml',
    ],
    info: '$_xmlRoot/oreamnos_engagement_widget_info.xml',
  ),
  _WidgetSpec(
    name: 'Drafts',
    provider: '$_providerRoot/OreamnosDraftsWidgetProvider.java',
    layouts: [
      '$_widgetRoot/oreamnos_drafts_widget.xml',
      '$_widgetRoot/oreamnos_drafts_widget_square.xml',
      '$_widgetRoot/oreamnos_drafts_widget_row.xml',
    ],
    info: '$_xmlRoot/oreamnos_drafts_widget_info.xml',
  ),
  _WidgetSpec(
    name: 'Best time',
    provider: '$_providerRoot/OreamnosBestTimeWidgetProvider.java',
    layouts: [
      '$_widgetRoot/oreamnos_best_time_widget.xml',
      '$_widgetRoot/oreamnos_best_time_widget_square.xml',
      '$_widgetRoot/oreamnos_best_time_widget_row.xml',
    ],
    info: '$_xmlRoot/oreamnos_best_time_widget_info.xml',
  ),
];

const _base = '$_providerRoot/BaseOreamnosWidget.java';

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

Set<String> _javaIds(String java) => {
  for (final match in RegExp(r'R\.id\.([a-z0-9_]+)').allMatches(java))
    match.group(1)!,
};

void main() {
  group('widget layouts are RemoteViews-safe', () {
    final allLayouts = [for (final widget in _widgets) ...widget.layouts];

    for (final path in allLayouts) {
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

    test('every layout declares the shared id set', () {
      for (final path in allLayouts) {
        final ids = _viewIds(_read(path));
        expect(
          _commonIds.difference(ids),
          isEmpty,
          reason:
              '$path is missing the shared widget_root/body/notice/footer ids',
        );
      }
    });

    for (final widget in _widgets) {
      test('${widget.name} exposes every id its provider binds', () {
        final required = _javaIds(_read(widget.provider)).union(_commonIds);
        expect(required, isNotEmpty);

        for (final path in widget.layouts) {
          final ids = _viewIds(_read(path));
          expect(
            required.difference(ids),
            isEmpty,
            reason: '$path is missing ids ${widget.provider} sets',
          );
        }
      });

      test('${widget.name} layouts share one view-id set', () {
        // The provider renders every size class with one code path, so a
        // missing id in one file is a NullPointerException waiting to happen.
        final first = _viewIds(_read(widget.layouts.first));
        for (final path in widget.layouts.skip(1)) {
          expect(
            _viewIds(_read(path)),
            first,
            reason: '${widget.name} layouts diverge at $path',
          );
        }
      });

      test('${widget.name} maps every size class to its own layout', () {
        final referenced = {
          for (final match in RegExp(
            r'R\.layout\.([a-z0-9_]+)',
          ).allMatches(_read(widget.provider)))
            '$_widgetRoot/${match.group(1)!}.xml',
        };
        expect(referenced, widget.layouts.toSet());
      });
    }

    test('pending intents are immutable with unique request codes', () {
      final java = _read(_base);
      expect(java, contains('PendingIntent.FLAG_IMMUTABLE'));

      final codes = [
        for (final match in RegExp(
          r'static final int (REQ_[A-Z_]+) = (\d+);',
        ).allMatches(java))
          match.group(2)!,
      ];
      expect(codes, isNotEmpty);
      expect(codes.toSet().length, codes.length);
    });

    test('every provider routes taps through the shared click helper', () {
      for (final widget in _widgets) {
        expect(
          _read(widget.provider),
          contains('bindClick('),
          reason: '${widget.name} has no tap target',
        );
      }
    });

    test('every widget allows shrinking to a one-row strip', () {
      for (final widget in _widgets) {
        final info = _read(widget.info);
        expect(info, contains('android:minResizeWidth="110dp"'));
        expect(info, contains('android:minResizeHeight="40dp"'));
        expect(info, contains('android:resizeMode="horizontal|vertical"'));
        expect(
          info.contains('android:configure='),
          widget.configurable,
          reason:
              '${widget.name}: only the widgets with a choice show a configure '
              'screen',
        );
      }
    });
  });
}
