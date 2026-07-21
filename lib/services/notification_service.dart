import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int _appReminderId = 1000;
  static const int _sleepId = 2000;
  static const int _feedId = 3000;
  static const int _sleepWindowId = 4000;
  static const int _diaperPeeId = 5000;
  static const int _diaperPoopId = 6000;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  static Future<void> scheduleAppReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      _appReminderId,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'app_reminder',
          'App Reminders',
          channelDescription: 'Reminders to use the app',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleSleepNotification({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _sleepId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_reminders',
          'Sleep Reminders',
          channelDescription: 'Reminders for upcoming naps',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleFeedNotification({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _feedId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'feed_reminders',
          'Feed Reminders',
          channelDescription: 'Reminders for upcoming feedings',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleSleepWindowNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _sleepWindowId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_window',
          'Sleep Window',
          channelDescription: 'Alerts when sleep window is closing',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> scheduleDiaperPeeReminder({
    required String title,
    required String body,
  }) async {
    await _plugin.periodicallyShow(
      _diaperPeeId,
      title,
      body,
      RepeatInterval.hourly,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diaper_pee',
          'Pee Check Reminders',
          channelDescription: 'Reminders to check for pee',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleDiaperPoopReminder({
    required String title,
    required String body,
  }) async {
    await _plugin.periodicallyShow(
      _diaperPoopId,
      title,
      body,
      RepeatInterval.hourly,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diaper_poop',
          'Poop Check Reminders',
          channelDescription: 'Reminders to check for poop',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelSleepNotification() async {
    await _plugin.cancel(_sleepId);
  }

  static Future<void> cancelFeedNotification() async {
    await _plugin.cancel(_feedId);
  }

  static Future<void> cancelAppReminder() async {
    await _plugin.cancel(_appReminderId);
  }

  static Future<void> cancelDiaperPeeReminder() async {
    await _plugin.cancel(_diaperPeeId);
  }

  static Future<void> cancelDiaperPoopReminder() async {
    await _plugin.cancel(_diaperPoopId);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
