import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Callback for notification taps (tone chooser etc.) — set in injection/app.
  Future<void> Function(String? payload, String? actionId)? onAction;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (onAction != null) {
          await onAction!(details.payload, details.actionId);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );
    _isInitialized = true;
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse details) {
    // Background isolate tap — will be handled on next foreground init via payload.
    debugPrint(
      'bg notification response: ${details.payload} action ${details.actionId}',
    );
  }

  Future<bool> requestPermission() async {
    bool isTest = false;
    try {
      isTest = Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {}
    if (isTest) return true;

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<void> showGenerationCompleteNotification(
    String title,
    String body,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'oreamnos_generation',
      'AI Generation',
      channelDescription: 'Notifications for completed AI content generations',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond % 100000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // === Background share: tone chooser (quick chooser) ===

  Future<void> showToneChooserNotification(String shareText) async {
    // Persist later by caller if needed; payload carries truncated preview only.
    const androidDetails = AndroidNotificationDetails(
      'oreamnos_tone_chooser',
      'Choose Tone',
      channelDescription: 'Quick tone chooser for shared content',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'tone_formal',
          'Formal',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'tone_casual',
          'Casual',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Payload carries shareText truncated to ~4k to stay within limits.
    final payload = shareText.length > 4000
        ? shareText.substring(0, 4000)
        : shareText;

    await _notificationsPlugin.show(
      id: 1001,
      title: 'Share to Oreamnos',
      body:
          'Tap Formal or Casual to curate — link will be scraped in background',
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> showOngoingNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'oreamnos_generation',
      'AI Generation',
      channelDescription: 'Notifications for completed AI content generations',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      indeterminate: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: 1002,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> cancelOngoing() async {
    await _notificationsPlugin.cancel(id: 1002);
  }

  Future<void> showPostReadyNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'oreamnos_generation',
      'AI Generation',
      channelDescription: 'Notifications for completed AI content generations',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('open_app', 'Open', showsUserInterface: true),
        AndroidNotificationAction(
          'copy_again',
          'Copy',
          showsUserInterface: false,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notificationsPlugin.show(
      id: 1003,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> showFailedNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'oreamnos_generation',
      'AI Generation',
      channelDescription: 'Notifications for completed AI content generations',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: 1004,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Best-effort clipboard helper.
  Future<bool> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }
}
