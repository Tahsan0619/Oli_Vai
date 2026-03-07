import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

/// Singleton service for showing local push (popup) notifications on the device.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Must be called once before showing notifications (e.g. in main.dart).
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);

    // Request notification permission on Android 13+
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[LOCAL_NOTIF] Initialized');
  }

  /// Show a popup notification from an [AppNotification].
  Future<void> show(AppNotification notification) async {
    if (!_initialized) {
      debugPrint('[LOCAL_NOTIF] Not initialized, skipping');
      return;
    }

    // Skip empty/placeholder notifications (e.g. trigger reload signals)
    if (notification.id.isEmpty || notification.title.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'edte_routine_notifications',        // channel id
      'Routine Notifications',             // channel name
      channelDescription: 'Notifications for schedule changes, appointments, and reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    // Use hashCode of notification id as the int id for the local notification
    await _plugin.show(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }
}
