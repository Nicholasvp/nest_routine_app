import '../models/event.dart';

class PredictionResult {
  final String label;
  final DateTime? predictedTime;
  final int confidencePercent;

  PredictionResult({
    required this.label,
    this.predictedTime,
    this.confidencePercent = 0,
  });

  String timeUntilLabel(String noPrediction, String late) {
    if (predictedTime == null) return noPrediction;
    final diff = predictedTime!.difference(DateTime.now());
    if (diff.isNegative) return late;
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
  }

  Duration? get timeUntil {
    if (predictedTime == null) return null;
    return predictedTime!.difference(DateTime.now());
  }
}

class PredictionEngine {
  PredictionEngine._();

  static PredictionResult predictNextSleep(List<BabyEvent> events) {
    final sleeps = events
        .where((e) =>
            e.type == EventType.sleep &&
            e.endTime != null)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (sleeps.isEmpty) {
      final suggestedNap = _suggestDefaultNapWindow();
      return PredictionResult(
        label: 'Suggested nap time',
        predictedTime: suggestedNap,
        confidencePercent: 30,
      );
    }

    final recentSleeps = sleeps.take(5).toList();
    if (recentSleeps.isEmpty) {
      return PredictionResult(
        label: 'No pattern yet',
        confidencePercent: 0,
      );
    }

    double totalAwakeBefore = 0;
    int awakeCount = 0;
    for (int i = 0; i < recentSleeps.length - 1; i++) {
      final awakeGap = recentSleeps[i]
          .startTime
          .difference(recentSleeps[i + 1].endTime!)
          .inMinutes;
      if (awakeGap > 0 && awakeGap < 360) {
        totalAwakeBefore += awakeGap;
        awakeCount++;
      }
    }

    final avgAwakeMinutes =
        awakeCount > 0 ? totalAwakeBefore / awakeCount : 90.0;

    final lastEvent = events
        .where((e) =>
            e.type == EventType.sleep)
        .fold<DateTime?>(
          null,
          (prev, e) =>
              prev == null || e.startTime.isAfter(prev) ? e.startTime : prev,
        );

    final lastWakeUp = events
        .where((e) =>
            e.type == EventType.sleep && e.endTime != null)
        .fold<DateTime?>(
          null,
          (prev, e) =>
              prev == null || e.endTime!.isAfter(prev) ? e.endTime : prev,
        );

    if (lastWakeUp != null && lastEvent != null) {
      final awakeSince = DateTime.now().difference(lastWakeUp).inMinutes;
      if (awakeSince < avgAwakeMinutes) {
        final predicted = lastWakeUp
            .add(Duration(minutes: avgAwakeMinutes.round()));
        return PredictionResult(
          label: 'Next nap',
          predictedTime: predicted,
          confidencePercent: (awakeCount / 5 * 100).round().clamp(40, 90),
        );
      }

      if (lastEvent != lastWakeUp) {
        return PredictionResult(
          label: 'Sleeping',
          predictedTime: null,
          confidencePercent: 100,
        );
      }
    }

    final predicted = DateTime.now()
        .add(Duration(minutes: avgAwakeMinutes.round()));
    return PredictionResult(
      label: 'Next nap',
      predictedTime: predicted,
      confidencePercent: (awakeCount / 5 * 100).round().clamp(30, 70),
    );
  }

  static PredictionResult predictNextFeed(List<BabyEvent> events) {
    final feeds = events
        .where((e) => e.type == EventType.feed)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (feeds.isEmpty) {
      return PredictionResult(
        label: 'No feed data yet',
        confidencePercent: 0,
      );
    }

    final recentFeeds = feeds.take(5).toList();
    double totalGap = 0;
    int gapCount = 0;
    for (int i = 0; i < recentFeeds.length - 1; i++) {
      final gap = recentFeeds[i]
          .startTime
          .difference(recentFeeds[i + 1].startTime)
          .inMinutes;
      if (gap > 0 && gap < 480) {
        totalGap += gap;
        gapCount++;
      }
    }

    final avgInterval =
        gapCount > 0 ? totalGap / gapCount : 180.0;
    final lastFeedTime = feeds.first.startTime;
    final sinceLastFeed =
        DateTime.now().difference(lastFeedTime).inMinutes;

    if (sinceLastFeed >= avgInterval) {
      return PredictionResult(
        label: 'Feed now',
        predictedTime: DateTime.now(),
        confidencePercent: (sinceLastFeed / avgInterval * 100)
            .round()
            .clamp(50, 95),
      );
    }

    final predicted =
        lastFeedTime.add(Duration(minutes: avgInterval.round()));
    return PredictionResult(
      label: 'Next feed',
      predictedTime: predicted,
      confidencePercent: (gapCount / 5 * 100).round().clamp(40, 85),
    );
  }

  static PredictionResult predictNextDiaper(List<BabyEvent> events) {
    final diapers = events
        .where((e) => e.type == EventType.pee || e.type == EventType.poop)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (diapers.isEmpty) {
      return PredictionResult(
        label: 'No diaper data yet',
        confidencePercent: 0,
      );
    }

    final recentDiapers = diapers.take(10).toList();
    double totalGap = 0;
    int gapCount = 0;
    for (int i = 0; i < recentDiapers.length - 1; i++) {
      final gap = recentDiapers[i]
          .startTime
          .difference(recentDiapers[i + 1].startTime)
          .inMinutes;
      if (gap > 0 && gap < 360) {
        totalGap += gap;
        gapCount++;
      }
    }

    final avgInterval =
        gapCount > 0 ? totalGap / gapCount : 120.0;
    final lastDiaperTime = diapers.first.startTime;
    final sinceLastDiaper =
        DateTime.now().difference(lastDiaperTime).inMinutes;

    if (sinceLastDiaper >= avgInterval) {
      return PredictionResult(
        label: 'Change now',
        predictedTime: DateTime.now(),
        confidencePercent: (sinceLastDiaper / avgInterval * 100)
            .round()
            .clamp(50, 95),
      );
    }

    final predicted =
        lastDiaperTime.add(Duration(minutes: avgInterval.round()));
    return PredictionResult(
      label: 'Next diaper',
      predictedTime: predicted,
      confidencePercent: (gapCount / 10 * 100).round().clamp(30, 85),
    );
  }

  static DateTime _suggestDefaultNapWindow() {
    final now = DateTime.now();
    final hour = now.hour;
    if (hour < 9) {
      return DateTime(now.year, now.month, now.day, 9, 30);
    } else if (hour < 12) {
      return DateTime(now.year, now.month, now.day, hour + 1, 30);
    } else if (hour < 17) {
      return now.add(const Duration(hours: 2));
    } else {
      return DateTime(now.year, now.month, now.day, 20, 0);
    }
  }
}
