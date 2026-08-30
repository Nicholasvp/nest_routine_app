import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

typedef NotificationTapCallback = void Function(String payload);

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static NotificationTapCallback? _onTap;

  static const int _appReminderId = 1000;
  static const int _sleep15Id = 2001;
  static const int _sleep10Id = 2002;
  static const int _sleep5Id = 2003;
  static const int _sleepOnTimeId = 2004;
  static const int _feedId = 3000;
  static const int _sleepWindowId = 4000;
  static const int _diaperPeeId = 5000;
  static const int _diaperPoopId = 6000;
  static const int _wakeCheckId = 7000;

  static const String payloadWakeCheck = 'wake_check';

  static Future<void> initialize({NotificationTapCallback? onTap}) async {
    if (_initialized) return;
    _onTap = onTap;

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

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _onTap?.call(response.payload!);
        }
      },
    );
    _initialized = true;
  }

  static Future<bool> checkPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final settings = await ios.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    return true;
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
      id: _appReminderId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'app_reminder',
          'App Reminders',
          channelDescription: 'Reminders to use the app',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleSleepNotification({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await _scheduleSleepAt(
      id: _sleepOnTimeId,
      scheduledTime: scheduledTime,
      title: title,
      body: body,
    );
  }

  static Future<void> scheduleSleepAdvance15({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await _scheduleSleepAt(
      id: _sleep15Id,
      scheduledTime: scheduledTime,
      title: title,
      body: body,
    );
  }

  static Future<void> scheduleSleepAdvance10({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await _scheduleSleepAt(
      id: _sleep10Id,
      scheduledTime: scheduledTime,
      title: title,
      body: body,
    );
  }

  static Future<void> scheduleSleepAdvance5({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await _scheduleSleepAt(
      id: _sleep5Id,
      scheduledTime: scheduledTime,
      title: title,
      body: body,
    );
  }

  static Future<void> _scheduleSleepAt({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_reminders',
          'Sleep Reminders',
          channelDescription: 'Reminders for upcoming naps',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleFeedNotification({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _feedId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'feed_reminders',
          'Feed Reminders',
          channelDescription: 'Reminders for upcoming feedings',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleSleepWindowNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: _sleepWindowId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_window',
          'Sleep Window',
          channelDescription: 'Alerts when sleep window is closing',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> scheduleDiaperPeeReminder({
    required String title,
    required String body,
  }) async {
    await _plugin.periodicallyShow(
      id: _diaperPeeId,
      title: title,
      body: body,
      repeatInterval: RepeatInterval.hourly,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'diaper_pee',
          'Pee Check Reminders',
          channelDescription: 'Reminders to check for pee',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleDiaperPoopReminder({
    required String title,
    required String body,
  }) async {
    await _plugin.periodicallyShow(
      id: _diaperPoopId,
      title: title,
      body: body,
      repeatInterval: RepeatInterval.hourly,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'diaper_poop',
          'Poop Check Reminders',
          channelDescription: 'Reminders to check for poop',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelSleepNotification() async {
    await _plugin.cancel(id: _sleep15Id);
    await _plugin.cancel(id: _sleep10Id);
    await _plugin.cancel(id: _sleep5Id);
    await _plugin.cancel(id: _sleepOnTimeId);
  }

  static Future<void> cancelFeedNotification() async {
    await _plugin.cancel(id: _feedId);
  }

  static Future<void> cancelAppReminder() async {
    await _plugin.cancel(id: _appReminderId);
  }

  static Future<void> cancelDiaperPeeReminder() async {
    await _plugin.cancel(id: _diaperPeeId);
  }

  static Future<void> cancelDiaperPoopReminder() async {
    await _plugin.cancel(id: _diaperPoopId);
  }

  static Future<void> scheduleWakeCheck({
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _wakeCheckId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'wake_check',
          'Wake-up Checks',
          channelDescription: 'Reminders to check if baby woke up',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payloadWakeCheck,
    );
  }

  static Future<void> cancelWakeCheck() async {
    await _plugin.cancel(id: _wakeCheckId);
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
