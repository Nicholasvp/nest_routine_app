import 'package:home_widget/home_widget.dart';
import '../models/event.dart';
import '../utils/storage_service.dart';

class WidgetService {
  static const _groupId = 'group.com.nestroutine.nestroutine';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_groupId);
  }

  static String _currentLocale() {
    return StorageService.getLocale() ?? 'en';
  }

  static Future<void> updateWidget({
    required String babyName,
    required bool isSleeping,
    required bool isFeeding,
    required String? lastSleepTime,
    required String? lastFeedTime,
    required String sleepToday,
    String? locale,
  }) async {
    locale ??= _currentLocale();
    await HomeWidget.saveWidgetData<String>('widget_baby_name', babyName);
    await HomeWidget.saveWidgetData<bool>('widget_is_sleeping', isSleeping);
    await HomeWidget.saveWidgetData<bool>('widget_is_feeding', isFeeding);
    await HomeWidget.saveWidgetData<String?>('widget_last_sleep_time', lastSleepTime);
    await HomeWidget.saveWidgetData<String?>('widget_last_feed_time', lastFeedTime);
    await HomeWidget.saveWidgetData<String>('widget_sleep_today', sleepToday);
    await HomeWidget.saveWidgetData<String>('widget_locale', locale);

    await HomeWidget.updateWidget(
      iOSName: 'NestRoutineWidget',
      androidName: 'NestRoutineWidget',
    );
  }

  static Future<void> updateFromEventData({
    required String babyName,
    required BabyEvent? activeSleep,
    required BabyEvent? activeFeed,
    required List<BabyEvent> events,
    required double totalSleepToday,
    String? locale,
  }) async {
    final isSleeping = activeSleep != null;
    final isFeeding = activeFeed != null;

    String? lastSleepTime;
    String? lastFeedTime;

    if (activeSleep != null) {
      lastSleepTime = _formatActiveDuration(activeSleep.startTime);
    } else {
      final sleepEvents = events
          .where((e) => e.type == EventType.sleep && e.endTime != null)
          .toList()
        ..sort((a, b) => b.endTime!.compareTo(a.endTime!));
      if (sleepEvents.isNotEmpty) {
        lastSleepTime = _formatRelativeTime(sleepEvents.first.endTime!);
      }
    }

    final feedEvents = events
        .where((e) => e.type == EventType.feed && e.endTime != null)
        .toList()
      ..sort((a, b) => b.endTime!.compareTo(a.endTime!));

    if (feedEvents.isNotEmpty) {
      lastFeedTime = _formatRelativeTime(feedEvents.first.endTime!);
    }

    final sleepHours = totalSleepToday;
    final sleepLabel = sleepHours > 0
        ? '${sleepHours.toStringAsFixed(1)}h hoje'
        : '0h hoje';

    await updateWidget(
      babyName: babyName,
      isSleeping: isSleeping,
      isFeeding: isFeeding,
      lastSleepTime: lastSleepTime,
      lastFeedTime: lastFeedTime,
      sleepToday: sleepLabel,
      locale: locale ?? _currentLocale(),
    );
  }

  static String _formatActiveDuration(DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    if (duration.inMinutes < 1) return 'agora';
    if (duration.inHours < 1) return '${duration.inMinutes}min';
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
  }

  static String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }
}
