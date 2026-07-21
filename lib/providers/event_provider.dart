import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../utils/prediction_engine.dart';
import '../utils/storage_service.dart';
import 'notification_provider.dart';

class EventProvider extends ChangeNotifier {
  final Map<String, List<BabyEvent>> _eventsByBaby = {};
  Timer? _tickTimer;

  BabyEvent? _activeSleepTimer;
  BabyEvent? _activeFeedTimer;
  NotificationProvider? _notificationProvider;

  BabyEvent? get activeSleepTimer => _activeSleepTimer;
  BabyEvent? get activeFeedTimer => _activeFeedTimer;

  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  List<BabyEvent> getEvents(String babyId) {
    return _eventsByBaby[babyId] ?? [];
  }

  List<BabyEvent> getTodayEvents(String babyId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final events = _eventsByBaby[babyId] ?? [];
    return events.where((e) {
      return e.startTime.isAfter(today) ||
          (e.endTime != null && e.endTime!.isAfter(today));
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<BabyEvent> getEventsForDay(String babyId, DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final events = _eventsByBaby[babyId] ?? [];
    return events.where((e) {
      return (e.startTime.isAfter(startOfDay) &&
              e.startTime.isBefore(endOfDay)) ||
          (e.endTime != null &&
              e.endTime!.isAfter(startOfDay) &&
              e.endTime!.isBefore(endOfDay)) ||
          (e.startTime.isBefore(startOfDay) &&
              e.endTime != null &&
              e.endTime!.isAfter(startOfDay));
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<BabyEvent> getSleepEvents(String babyId) {
    return (getEvents(babyId))
        .where((e) => e.type == EventType.sleep)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  void loadEvents(String babyId) {
    final events = StorageService.loadEvents(babyId);
    _eventsByBaby[babyId] = events;
    _updateActiveTimers(babyId);
    notifyListeners();
  }

  void _updateActiveTimers(String babyId) {
    final events = _eventsByBaby[babyId] ?? [];
    final ongoing = events.where((e) => e.isOngoing).toList();
    _activeSleepTimer = ongoing.where((e) => e.type == EventType.sleep).firstOrNull;
    _activeFeedTimer = ongoing.where((e) => e.type == EventType.feed).firstOrNull;
    _updateTickTimerState();
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _stopTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  Future<void> addEvent(BabyEvent event) async {
    _eventsByBaby[event.babyId] ??= [];
    _eventsByBaby[event.babyId]!.insert(0, event);
    _updateActiveTimers(event.babyId);
    await StorageService.saveEvents(event.babyId, _eventsByBaby[event.babyId]!);
    notifyListeners();

    _notificationProvider?.onEventAdded(
      events: _eventsByBaby[event.babyId] ?? [],
    );
  }

  Future<BabyEvent> startSleepTimer(String babyId) async {
    final event = BabyEvent(
      id: const Uuid().v4(),
      babyId: babyId,
      type: EventType.sleep,
      startTime: DateTime.now(),
    );
    _eventsByBaby[babyId] ??= [];
    _eventsByBaby[babyId]!.insert(0, event);
    _activeSleepTimer = event;
    _startTickTimer();
    await StorageService.saveEvents(babyId, _eventsByBaby[babyId]!);
    notifyListeners();
    return event;
  }

  Future<void> stopSleepTimer(String babyId, {DateTime? endTime}) async {
    if (_activeSleepTimer == null) return;
    final index = _eventsByBaby[babyId]
            ?.indexWhere((e) => e.id == _activeSleepTimer!.id) ??
        -1;
    if (index == -1) return;
    final updated = _activeSleepTimer!.copyWith(
      endTime: endTime ?? DateTime.now(),
    );
    _eventsByBaby[babyId]![index] = updated;
      _activeSleepTimer = null;
    _updateTickTimerState();
    await StorageService.saveEvents(babyId, _eventsByBaby[babyId]!);
    notifyListeners();
  }

  Future<BabyEvent> startFeedTimer(String babyId) async {
    final event = BabyEvent(
      id: const Uuid().v4(),
      babyId: babyId,
      type: EventType.feed,
      startTime: DateTime.now(),
      feedType: FeedType.breast,
    );
    _eventsByBaby[babyId] ??= [];
    _eventsByBaby[babyId]!.insert(0, event);
    _activeFeedTimer = event;
    _startTickTimer();
    await StorageService.saveEvents(babyId, _eventsByBaby[babyId]!);
    notifyListeners();
    return event;
  }

  Future<void> stopFeedTimer(String babyId, {DateTime? endTime, FeedSide? feedSide, int? durationMinutes}) async {
    if (_activeFeedTimer == null) return;
    final index = _eventsByBaby[babyId]
            ?.indexWhere((e) => e.id == _activeFeedTimer!.id) ??
        -1;
    if (index == -1) return;
    final updated = _activeFeedTimer!.copyWith(
      endTime: endTime ?? DateTime.now(),
      feedSide: feedSide,
      durationMinutes: durationMinutes ??
          (endTime ?? DateTime.now())
              .difference(_activeFeedTimer!.startTime)
              .inMinutes,
    );
    _eventsByBaby[babyId]![index] = updated;
    _activeFeedTimer = null;
    _updateTickTimerState();
    await StorageService.saveEvents(babyId, _eventsByBaby[babyId]!);
    notifyListeners();
  }

  void _updateTickTimerState() {
    if (_activeSleepTimer != null || _activeFeedTimer != null) {
      _startTickTimer();
    } else {
      _stopTickTimer();
    }
  }

  Future<void> removeEvent(String babyId, String eventId) async {
    _eventsByBaby[babyId]?.removeWhere((e) => e.id == eventId);
    _updateActiveTimers(babyId);
    await StorageService.saveEvents(
        babyId, _eventsByBaby[babyId] ?? []);
    notifyListeners();
  }

  Future<void> updateEvent(BabyEvent event) async {
    final events = _eventsByBaby[event.babyId];
    if (events == null) return;
    final index = events.indexWhere((e) => e.id == event.id);
    if (index == -1) return;
    events[index] = event;
    _updateActiveTimers(event.babyId);
    await StorageService.saveEvents(event.babyId, events);
    notifyListeners();
  }

  PredictionResult predictNextNap(String babyId) {
    final events = _eventsByBaby[babyId] ?? [];
    return PredictionEngine.predictNextSleep(events);
  }

  PredictionResult predictNextFeed(String babyId) {
    final events = _eventsByBaby[babyId] ?? [];
    return PredictionEngine.predictNextFeed(events);
  }

  PredictionResult predictNextDiaper(String babyId) {
    final events = _eventsByBaby[babyId] ?? [];
    return PredictionEngine.predictNextDiaper(events);
  }

  double getTotalSleepToday(String babyId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final events = _eventsByBaby[babyId] ?? [];
    double totalMinutes = 0;
    for (final e in events) {
      if (e.type == EventType.sleep && e.endTime != null) {
        if (e.endTime!.isAfter(startOfDay) || e.startTime.isAfter(startOfDay)) {
          final effectiveStart =
              e.startTime.isAfter(startOfDay) ? e.startTime : startOfDay;
          final effectiveEnd = e.endTime!;
          if (effectiveEnd.isAfter(effectiveStart)) {
            totalMinutes +=
                effectiveEnd.difference(effectiveStart).inMinutes;
          }
        }
      }
    }
    if (_activeSleepTimer != null) {
      totalMinutes +=
          DateTime.now().difference(_activeSleepTimer!.startTime).inMinutes;
    }
    return totalMinutes / 60;
  }

  double getTotalSleepForDay(String babyId, DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final events = _eventsByBaby[babyId] ?? [];
    double totalMinutes = 0;
    for (final e in events) {
      if (e.type == EventType.sleep && e.endTime != null) {
        final effectiveStart =
            e.startTime.isAfter(startOfDay) ? e.startTime : startOfDay;
        final effectiveEnd =
            e.endTime!.isBefore(endOfDay) ? e.endTime! : endOfDay;
        if (effectiveEnd.isAfter(effectiveStart)) {
          totalMinutes +=
              effectiveEnd.difference(effectiveStart).inMinutes;
        }
      }
    }
    return totalMinutes / 60;
  }

  double getAverageSleepPerDay(String babyId, {int days = 7}) {
    final now = DateTime.now();
    double total = 0;
    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      total += getTotalSleepForDay(babyId, day);
    }
    return total / days;
  }

  double getAverageFeedInterval(String babyId, {int days = 3}) {
    final events = _eventsByBaby[babyId] ?? [];
    final feeds = events
        .where((e) =>
            e.type == EventType.feed &&
            e.startTime
                .isAfter(DateTime.now().subtract(Duration(days: days))))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (feeds.length < 2) return 0;
    double totalGap = 0;
    for (int i = 1; i < feeds.length; i++) {
      totalGap +=
          feeds[i].startTime.difference(feeds[i - 1].startTime).inMinutes;
    }
    return totalGap / (feeds.length - 1);
  }

  Map<DateTime, double> getSleepHoursPerDay(String babyId,
      {int days = 7}) {
    final result = <DateTime, double>{};
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      result[day] = getTotalSleepForDay(babyId, day);
    }
    return result;
  }

  List<BabyEvent> _eventsInRange(String babyId, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (_eventsByBaby[babyId] ?? [])
        .where((e) => e.startTime.isAfter(cutoff))
        .toList();
  }

  // Feed analytics

  Map<DateTime, int> getFeedVolumeByDay(String babyId, {int days = 7}) {
    final result = <DateTime, int>{};
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      result[day] = 0;
    }
    final events = _eventsInRange(babyId, days);
    for (final e in events) {
      if (e.type == EventType.feed && e.volumeMl != null) {
        final day = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
        result.update(day, (v) => v + e.volumeMl!, ifAbsent: () => e.volumeMl!);
      }
    }
    return result;
  }

  double getBreastFeedRatio(String babyId, {int days = 7}) {
    final events = _eventsInRange(babyId, days);
    final feeds = events.where((e) => e.type == EventType.feed).toList();
    if (feeds.isEmpty) return 0;
    final breast = feeds.where((e) => e.feedType == FeedType.breast).length;
    return breast / feeds.length;
  }

  Map<FeedSide, int> getFeedSideDistribution(String babyId, {int days = 7}) {
    final events = _eventsInRange(babyId, days);
    final sides = {FeedSide.left: 0, FeedSide.right: 0, FeedSide.both: 0};
    for (final e in events) {
      if (e.type == EventType.feed && e.feedSide != null) {
        sides[e.feedSide!] = (sides[e.feedSide!] ?? 0) + 1;
      }
    }
    return sides;
  }

  Map<DateTime, int> getFeedCountByDay(String babyId, {int days = 7}) {
    final result = <DateTime, int>{};
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      result[day] = 0;
    }
    final events = _eventsInRange(babyId, days);
    for (final e in events) {
      if (e.type == EventType.feed) {
        final day = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
        result.update(day, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return result;
  }

  // Diaper analytics

  Map<DateTime, int> getDiaperCountByDay(String babyId, {int days = 7}) {
    final result = <DateTime, int>{};
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      result[day] = 0;
    }
    final events = _eventsInRange(babyId, days);
    for (final e in events) {
      if (e.type == EventType.pee || e.type == EventType.poop) {
        final day = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
        result.update(day, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return result;
  }

  (int peeOnly, int poopOnly, int both) getPeePoopBreakdown(
      String babyId, {int days = 7}) {
    final events = _eventsInRange(babyId, days);
    int pee = 0, poop = 0, both = 0;
    for (final e in events) {
      if (e.type == EventType.pee || e.type == EventType.poop) {
        if (e.hasPee && e.hasPoop) {
          both++;
        } else if (e.hasPee) {
          pee++;
        } else if (e.hasPoop) {
          poop++;
        }
      }
    }
    return (pee, poop, both);
  }

  Map<DiaperTexture, int> getDiaperTextureDistribution(
      String babyId, {int days = 7}) {
    final events = _eventsInRange(babyId, days);
    final textures = <DiaperTexture, int>{};
    for (final e in events) {
      if (e.diaperTexture != null) {
        textures[e.diaperTexture!] =
            (textures[e.diaperTexture!] ?? 0) + 1;
      }
    }
    return textures;
  }

  int getTotalDiaperChanges(String babyId, {int days = 7}) {
    final events = _eventsInRange(babyId, days);
    return events.where((e) => e.type == EventType.pee || e.type == EventType.poop).length;
  }

  double getAverageDiapersPerDay(String babyId, {int days = 7}) {
    final total = getTotalDiaperChanges(babyId, days: days);
    return total / days;
  }

  int getTotalFeeds(String babyId, {int days = 7}) {
    final events = _eventsInRange(babyId, days);
    return events.where((e) => e.type == EventType.feed).length;
  }

  double getAverageFeedsPerDay(String babyId, {int days = 7}) {
    final total = getTotalFeeds(babyId, days: days);
    return total / days;
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
