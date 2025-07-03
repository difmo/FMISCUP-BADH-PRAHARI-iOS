/*
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
  }

  static Future<void> scheduleMultipleNotifications() async {
    final times = [
      {'id': 101, 'hour': 4, 'minute': 0},
      {'id': 102, 'hour': 8, 'minute': 0},
      {'id': 103, 'hour': 10, 'minute': 54},
      {'id': 104, 'hour': 16, 'minute': 0},
      {'id': 105, 'hour': 20, 'minute': 0},
    ];

    for (var time in times) {
      await _notificationsPlugin.zonedSchedule(
        time['id']!,
        'Flood Data Sync Reminder',
        'Time to sync your local data.',
        _nextInstance(time['hour']!, time['minute']!),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sync_channel_id',
            'Sync Reminders',
            channelDescription: 'Reminders to sync local data',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'instant_channel_id',
          'Instant Alerts',
          channelDescription: 'Immediate alert notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(0, title, body, notificationDetails);
  }
}
*/
