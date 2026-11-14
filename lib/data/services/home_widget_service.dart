import 'dart:async';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:injectable/injectable.dart';

import 'package:oreamnos/domain/models/home_widget_snapshot.dart';

import 'log_service.dart';

/// Bridge between the Dart app state and the native home-screen widget.
///
/// The widget is Android-only for now: it renders from a small string payload
/// written through `home_widget`, and every tap opens the app on a go_router
/// location. Widgets never act in the background, so secure-storage tokens and
/// the generation stack stay out of reach of a home-screen surface.
@lazySingleton
class HomeWidgetService {
  HomeWidgetService(this._log);

  final LogService _log;

  /// Must match the `<receiver android:name=".widget.OreamnosWidgetProvider">`.
  static const String qualifiedAndroidProvider =
      'com.najmi.oreamnos.widget.OreamnosWidgetProvider';

  bool _warned = false;

  bool get isSupported => Platform.isAndroid;

  /// Warm-start taps. Only listen on Android; other platforms have no plugin.
  Stream<Uri?> get clicks => HomeWidget.widgetClicked;

  /// Cold-start tap, if the launcher launched us from a widget.
  Future<Uri?> initialLaunchUri() async {
    if (!isSupported) return null;
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (error) {
      _warn('read initial widget launch', error);
      return null;
    }
  }

  /// Pushes [snapshot] to the widget and arms the next refresh.
  ///
  /// Never throws: a widget write failing must not disturb the app, which is
  /// why the caller does not need to guard this call.
  Future<bool> push(HomeWidgetSnapshot snapshot) async {
    if (!isSupported) return false;
    try {
      for (final entry in snapshot.toMap().entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: qualifiedAndroidProvider,
      );
      await _scheduleRefreshes(snapshot);
      return true;
    } catch (error) {
      _warn('push widget snapshot', error);
      return false;
    }
  }

  /// The widget copy is time-sensitive in exactly two places: the next post
  /// going live, and the Pacific quota reset. `updatePeriodMillis` (30 min)
  /// covers everything else, including the "updated 2d ago" staleness line.
  ///
  /// The plugin uses AlarmManager; without the exact-alarm permission these
  /// are inexact, which is fine for a countdown that also ticks locally.
  Future<void> _scheduleRefreshes(HomeWidgetSnapshot snapshot) async {
    final now = snapshot.updatedAt;
    final times = <DateTime>[
      if (snapshot.nextAt != null && snapshot.nextAt!.isAfter(now))
        snapshot.nextAt!.add(const Duration(minutes: 1)),
      if (snapshot.quotaResetAt != null && snapshot.quotaResetAt!.isAfter(now))
        snapshot.quotaResetAt!.add(const Duration(minutes: 1)),
    ];
    try {
      if (times.isEmpty) {
        await HomeWidget.cancelScheduledWidgetUpdates(
          qualifiedAndroidName: qualifiedAndroidProvider,
        );
      } else {
        await HomeWidget.scheduleWidgetUpdates(
          times,
          qualifiedAndroidName: qualifiedAndroidProvider,
        );
      }
    } catch (error) {
      _warn('schedule widget refresh', error);
    }
  }

  void _warn(String action, Object error) {
    if (_warned) return;
    _warned = true;
    _log.warning('Home widget $action failed: $error', tag: 'Widget');
  }
}
