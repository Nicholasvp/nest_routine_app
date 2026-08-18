import 'package:flutter/foundation.dart';
import '../models/notification_settings.dart';
import '../models/event.dart';
import '../utils/prediction_engine.dart';
import '../utils/sleep_window.dart';
import '../utils/storage_service.dart';
import '../services/notification_service.dart';
import 'locale_provider.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationSettingsModel _settings = NotificationSettingsModel();
  bool _permissionGranted = false;
  LocaleProvider? _localeProvider;

  NotificationSettingsModel get settings => _settings;
  bool get permissionGranted => _permissionGranted;

  bool get _isPortuguese => _localeProvider?.isPortuguese ?? false;

  void loadSettings() {
    final data = StorageService.loadNotificationSettings();
    if (data != null) {
      _settings = NotificationSettingsModel.fromMap(data);
    }
    _checkRealPermission();
    notifyListeners();
  }

  Future<void> _checkRealPermission() async {
    await NotificationService.initialize();
    _permissionGranted = await NotificationService.checkPermission();
    notifyListeners();
  }

  Future<void> saveSettings() async {
    await StorageService.saveNotificationSettings(_settings.toMap());
    notifyListeners();
  }

  Future<void> requestPermission() async {
    await NotificationService.initialize();
    _permissionGranted = await NotificationService.requestPermission();
    notifyListeners();
  }

  void setLocaleProvider(LocaleProvider provider) {
    _localeProvider = provider;
  }

  Future<void> updateAppReminder(bool enabled) async {
    _settings.appReminderEnabled = enabled;
    await saveSettings();
    if (enabled) {
      await _scheduleAppReminder();
    } else {
      await NotificationService.cancelAppReminder();
    }
  }

  Future<void> updateAppReminderTime(int hour, int minute) async {
    _settings.appReminderHour = hour;
    _settings.appReminderMinute = minute;
    await saveSettings();
    if (_settings.appReminderEnabled) {
      await _scheduleAppReminder();
    }
  }

  Future<void> updateSleepEnabled(bool enabled) async {
    _settings.sleepEnabled = enabled;
    await saveSettings();
    if (!enabled) {
      await NotificationService.cancelSleepNotification();
    }
  }

  Future<void> updateFeedEnabled(bool enabled) async {
    _settings.feedEnabled = enabled;
    await saveSettings();
    if (!enabled) {
      await NotificationService.cancelFeedNotification();
    }
  }

  Future<void> updateSleepWindowEnabled(bool enabled) async {
    _settings.sleepWindowEnabled = enabled;
    await saveSettings();
  }

  Future<void> updateDiaperPeeEnabled(bool enabled) async {
    _settings.diaperPeeEnabled = enabled;
    await saveSettings();
    if (enabled) {
      await _scheduleDiaperPeeReminder();
    } else {
      await NotificationService.cancelDiaperPeeReminder();
    }
  }

  Future<void> updateDiaperPoopEnabled(bool enabled) async {
    _settings.diaperPoopEnabled = enabled;
    await saveSettings();
    if (enabled) {
      await _scheduleDiaperPoopReminder();
    } else {
      await NotificationService.cancelDiaperPoopReminder();
    }
  }

  Future<void> updateDiaperInterval(int hours) async {
    _settings.diaperIntervalHours = hours;
    await saveSettings();
    if (_settings.diaperPeeEnabled) {
      await _scheduleDiaperPeeReminder();
    }
    if (_settings.diaperPoopEnabled) {
      await _scheduleDiaperPoopReminder();
    }
  }

  Future<void> onEventAdded({
    required List<BabyEvent> events,
  }) async {
    final isPt = _isPortuguese;
    if (_settings.sleepEnabled) {
      await _rescheduleSleepNotification(events, isPt);
    }
    if (_settings.feedEnabled) {
      await _rescheduleFeedNotification(events, isPt);
    }
    if (_settings.sleepWindowEnabled) {
      await _checkSleepWindow(events, isPt);
    }
  }

  Future<void> _scheduleAppReminder() async {
    final title = _settings.appReminderHour < 12
        ? 'Good morning! ☀️'
        : 'How is baby doing? 👶';
    final body = _settings.appReminderHour < 12
        ? 'Time to log baby\'s morning routine'
        : 'Don\'t forget to track today\'s events';

    await NotificationService.scheduleAppReminder(
      hour: _settings.appReminderHour,
      minute: _settings.appReminderMinute,
      title: title,
      body: body,
    );
  }

  Future<void> _rescheduleSleepNotification(
    List<BabyEvent> events,
    bool isPortuguese,
  ) async {
    await NotificationService.cancelSleepNotification();

    final prediction = PredictionEngine.predictNextSleep(events);
    if (prediction.predictedTime == null) return;

    final scheduledTime = prediction.predictedTime!.subtract(
      Duration(minutes: _settings.sleepAdvanceMinutes),
    );

    if (scheduledTime.isBefore(DateTime.now())) return;

    final title = isPortuguese ? 'Hora da soneca! 😴' : 'Nap time! 😴';
    final body = isPortuguese
        ? 'O bebê pode precisar dormir em ${_settings.sleepAdvanceMinutes} minutos'
        : 'Baby may need to sleep in ${_settings.sleepAdvanceMinutes} minutes';

    await NotificationService.scheduleSleepNotification(
      scheduledTime: scheduledTime,
      title: title,
      body: body,
    );
  }

  Future<void> _rescheduleFeedNotification(
    List<BabyEvent> events,
    bool isPortuguese,
  ) async {
    await NotificationService.cancelFeedNotification();

    final prediction = PredictionEngine.predictNextFeed(events);
    if (prediction.predictedTime == null) return;

    final scheduledTime = prediction.predictedTime!.subtract(
      Duration(minutes: _settings.feedAdvanceMinutes),
    );

    if (scheduledTime.isBefore(DateTime.now())) return;

    final title = isPortuguese ? 'Hora de mamar! 🍼' : 'Feeding time! 🍼';
    final body = isPortuguese
        ? 'O bebê pode ter fome em ${_settings.feedAdvanceMinutes} minutos'
        : 'Baby may be hungry in ${_settings.feedAdvanceMinutes} minutes';

    await NotificationService.scheduleFeedNotification(
      scheduledTime: scheduledTime,
      title: title,
      body: body,
    );
  }

  Future<void> _checkSleepWindow(
    List<BabyEvent> events,
    bool isPortuguese,
  ) async {
    final lastWakeUp = events
        .where((e) => e.type == EventType.sleep && e.endTime != null)
        .fold<DateTime?>(
          null,
          (prev, e) =>
              prev == null || e.endTime!.isAfter(prev) ? e.endTime : prev,
        );

    if (lastWakeUp == null) return;

    final calculator = SleepBatteryCalculator(
      ageMonths: 6,
      lastWakeUp: lastWakeUp,
    );

    if (calculator.state == BatteryState.warning ||
        calculator.state == BatteryState.critical) {
      final title = isPortuguese
          ? 'Janela de sono fechando! ⚠️'
          : 'Sleep window closing! ⚠️';
      final body = isPortuguese
          ? 'O bebê pode ficar exausto. Considere colocar para dormir.'
          : 'Baby may get overtired. Consider putting to sleep.';

      await NotificationService.scheduleSleepWindowNotification(
        title: title,
        body: body,
      );
    }
  }

  Future<void> _scheduleDiaperPeeReminder() async {
    const title = 'Time to check! 💧';
    const body = 'Check if baby needs a diaper change';

    await NotificationService.scheduleDiaperPeeReminder(
      title: title,
      body: body,
    );
  }

  Future<void> _scheduleDiaperPoopReminder() async {
    const title = 'Time to check! 💩';
    const body = 'Check if baby needs a diaper change';

    await NotificationService.scheduleDiaperPoopReminder(
      title: title,
      body: body,
    );
  }

  Future<void> cancelAllNotifications() async {
    await NotificationService.cancelAll();
  }
}
