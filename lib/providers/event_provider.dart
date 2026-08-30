import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../utils/prediction_engine.dart';
import '../utils/storage_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../services/widget_service.dart';
import 'notification_provider.dart';

class EventProvider extends ChangeNotifier {
  final Map<String, List<BabyEvent>> _eventsByBaby = {};
  Timer? _tickTimer;

  BabyEvent? _activeSleepTimer;
  BabyEvent? _activeFeedTimer;
  NotificationProvider? _notificationProvider;
  SyncService? _syncService;
  AnalyticsService? _analyticsService;

  BabyEvent? get activeSleepTimer => _activeSleepTimer;
  BabyEvent? get activeFeedTimer => _activeFeedTimer;

  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  void initSyncService(AuthService authService) {
    _syncService = SyncService(authService);
    _analyticsService = AnalyticsService(authService);
  }

  List<BabyEvent> getEvents(String babyId) {
    return _eventsByBaby[babyId] ?? [];
  }

  void clearEvents() {
    _eventsByBaby.clear();
    _activeSleepTimer = null;
    _activeFeedTimer = null;
    _stopTickTimer();
    notifyListeners();
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

  Future<void> loadEventsFromCloud(String babyId) async {
    if (_syncService == null || !_syncService!.isLoggedIn) return;
    try {
      final cloudEvents = await _syncService!.loadEventsFromSupabase(babyId);
      if (cloudEvents.isNotEmpty) {
        final localEvents = _eventsByBaby[babyId] ?? [];
        final merged = _mergeEvents(localEvents, cloudEvents);
        _eventsByBaby[babyId] = merged;
        await StorageService.saveEvents(babyId, merged);
        _updateActiveTimers(babyId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[EventProvider] Failed to load events from cloud: $e');
    }
  }

  List<BabyEvent> _mergeEvents(List<BabyEvent> local, List<BabyEvent> cloud) {
    final map = <String, BabyEvent>{};
    for (final e in local) {
      map[e.id] = e;
    }
    for (final e in cloud) {
      final existing = map[e.id];
      if (existing == null) {
        map[e.id] = e;
      } else {
        final localTime = existing.endTime ?? existing.startTime;
        final cloudTime = e.endTime ?? e.startTime;
        if (cloudTime.isAfter(localTime)) {
          map[e.id] = e;
        }
      }
    }
    final merged = map.values.toList();
    merged.sort((a, b) => b.startTime.compareTo(a.startTime));
    return merged;
  }

  void _refreshWidget(String babyId, {String? babyName}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final name = babyName ?? 'Baby';
      final events = _eventsByBaby[babyId] ?? [];
      WidgetService.updateFromEventData(
        babyName: name,
        activeSleep: _activeSleepTimer,
        activeFeed: _activeFeedTimer,
        events: events,
        totalSleepToday: getTotalSleepToday(babyId),
      );
    });
  }

  void _updateActiveTimers(String babyId) {
    final events = _eventsByBaby[babyId];
    if (events == null || events.isEmpty) {
      _activeSleepTimer = null;
      _activeFeedTimer = null;
      _updateTickTimerState();
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool needsSave = false;

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      if (!event.isOngoing) continue;

      if (event.startTime.isBefore(today)) {
        events[i] = event.copyWith(endTime: today);
        needsSave = true;
      } else if (event.type == EventType.feed &&
          now.difference(event.startTime).inMinutes >= 60) {
        events[i] = event.copyWith(
          endTime: event.startTime.add(const Duration(hours: 1)),
          durationMinutes: 60,
        );
        needsSave = true;
      }
    }

    if (needsSave) {
      StorageService.saveEvents(babyId, events);
    }

    final ongoing = events
        .where((e) => e.isOngoing && !e.startTime.isBefore(today))
        .toList();
    _activeSleepTimer =
        ongoing.where((e) => e.type == EventType.sleep).firstOrNull;
    _activeFeedTimer =
        ongoing.where((e) => e.type == EventType.feed).firstOrNull;
    _updateTickTimerState();
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _autoStopFeedIfNeeded();
      notifyListeners();
    });
  }

  void _autoStopFeedIfNeeded() {
    if (_activeFeedTimer == null) return;
    if (DateTime.now().difference(_activeFeedTimer!.startTime).inMinutes >=
        60) {
      stopFeedTimer(
        _activeFeedTimer!.babyId,
        endTime:
            _activeFeedTimer!.startTime.add(const Duration(hours: 1)),
        feedSide: _activeFeedTimer!.feedSide,
        durationMinutes: 60,
      );
    }
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
    _syncService?.syncEventToSupabase(event);
    _analyticsService?.log(AnalyticsService.addEvent, AnalyticsService.usage, properties: {
      'event_id': event.id,
      'baby_id': event.babyId,
      'event_type': event.type.name,
    });
    notifyListeners();
    _refreshWidget(event.babyId);

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
      fellAsleep: true,
    );
    _eventsByBaby[babyId] ??= [];
    _eventsByBaby[babyId]!.insert(0, event);
    _activeSleepTimer = event;
    _startTickTimer();
    await StorageService.saveEvents(babyId, _eventsByBaby[babyId]!);
    _syncService?.syncEventToSupabase(event);
    _analyticsService?.log(AnalyticsService.startSleep, AnalyticsService.usage, properties: {
      'event_id': event.id,
      'baby_id': babyId,
    });
    notifyListeners();
    _refreshWidget(babyId);
    _notificationProvider?.startWakeCheckLoop();
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
    _syncService?.syncEventToSupabase(updated);
    _analyticsService?.log(AnalyticsService.stopSleep, AnalyticsService.usage, properties: {
      'event_id': updated.id,
      'baby_id': babyId,
      'duration_minutes': updated.duration?.inMinutes,
    });
    notifyListeners();
    _refreshWidget(babyId);
    _notificationProvider?.cancelWakeCheckLoop();
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
    _syncService?.syncEventToSupabase(event);
    _analyticsService?.log(AnalyticsService.startFeed, AnalyticsService.usage, properties: {
      'event_id': event.id,
      'baby_id': babyId,
    });
    notifyListeners();
    _refreshWidget(babyId);
    return event;
  }

  Future<void> updateTimerFeedSide(String babyId, FeedSide feedSide) async {
    if (_activeFeedTimer == null) return;
    final index = _eventsByBaby[babyId]
            ?.indexWhere((e) => e.id == _activeFeedTimer!.id) ??
        -1;
    if (index == -1) return;
    final updated = _activeFeedTimer!.copyWith(feedSide: feedSide);
    _eventsByBaby[babyId]![index] = updated;
    _activeFeedTimer = updated;
    await StorageService.saveEvents(babyId, _eventsByBaby[babyId]!);
    notifyListeners();
    _refreshWidget(babyId);
  }

  Future<void> stopFeedTimer(String babyId, {DateTime? endTime, FeedSide? feedSide, int? durationMinutes, DateTime? startTime}) async {
    if (_activeFeedTimer == null) return;
    final index = _eventsByBaby[babyId]
            ?.indexWhere((e) => e.id == _activeFeedTimer!.id) ??
        -1;
    if (index == -1) return;
    final adjustedStart = startTime ?? _activeFeedTimer!.startTime;
    final updated = _activeFeedTimer!.copyWith(
      startTime: adjustedStart,
      endTime: endTime ?? DateTime.now(),
      feedSide: feedSide,
      durationMinutes: durationMinutes ??
          (endTime ?? DateTime.now())
              .difference(adjustedStart)
              .inMinutes,
    );
    _eventsByBaby[babyId]![index] = updated;
    _activeFeedTimer = null;
    _updateTickTimerState();
    await StorageService.saveEvents(babyId, _eventsByBaby[babyId]!);
    _syncService?.syncEventToSupabase(updated);
    _analyticsService?.log(AnalyticsService.stopFeed, AnalyticsService.usage, properties: {
      'event_id': updated.id,
      'baby_id': babyId,
      'duration_minutes': updated.durationMinutes,
      'feed_type': updated.feedType?.name,
      'feed_side': updated.feedSide?.name,
    });
    notifyListeners();
    _refreshWidget(babyId);
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
    _syncService?.deleteEventFromSupabase(eventId);
    notifyListeners();
    _refreshWidget(babyId);
  }

  Future<void> updateEvent(BabyEvent event) async {
    final events = _eventsByBaby[event.babyId];
    if (events == null) return;
    final index = events.indexWhere((e) => e.id == event.id);
    if (index == -1) return;
    events[index] = event;
    _updateActiveTimers(event.babyId);
    await StorageService.saveEvents(event.babyId, events);
    _syncService?.syncEventToSupabase(event);
    notifyListeners();
    _refreshWidget(event.babyId);
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
      final activeMinutes = DateTime.now().difference(_activeSleepTimer!.startTime).inMinutes;
      totalMinutes += activeMinutes.clamp(0, 1440);
    }
    final hours = totalMinutes / 60;
    return hours.clamp(0.0, 24.0);
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
    final hours = totalMinutes / 60;
    return hours.clamp(0.0, 24.0);
  }

  double getAverageSleepPerDay(String babyId, {int days = 7}) {
    final now = DateTime.now();
    double total = 0;
    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      total += getTotalSleepForDay(babyId, day);
    }
    final avg = total / days;
    return avg.clamp(0.0, 24.0);
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

  bool get shouldShowReview {
    final total = getAllEventsCount();
    return ReviewService.shouldShowPrompt(total);
  }

  void consumeReviewPrompt() {
    // No-op - review prompt is managed by ReviewService
  }

  int getAllEventsCount() {
    int total = 0;
    for (final events in _eventsByBaby.values) {
      total += events.length;
    }
    return total;
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
