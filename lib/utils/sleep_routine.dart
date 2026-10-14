import 'dart:math' as math;

import '../models/event.dart';

class SleepRoutineTime {
  final int minuteOfDay;

  const SleepRoutineTime(this.minuteOfDay);
}

List<SleepRoutineTime> findCommonSleepRoutine(List<BabyEvent> events) {
  final dayKeys = <String>{};
  final daysByNearbyHalfHours = <int, Set<String>>{};
  for (final event in events) {
    if (event.endTime == null) continue;
    final dayKey =
        '${event.startTime.year}-${event.startTime.month}-${event.startTime.day}';
    dayKeys.add(dayKey);
    final minute = event.startTime.hour * 60 + event.startTime.minute;
    final slot = ((minute / 30).round()) % 48;

    // Treat nearby start times as the same usual time instead of requiring
    // parents to log a sleep in the exact same half-hour every day.
    for (var offset = -1; offset <= 1; offset++) {
      final nearbySlot = (slot + offset + 48) % 48;
      daysByNearbyHalfHours
          .putIfAbsent(nearbySlot, () => <String>{})
          .add(dayKey);
    }
  }

  // A few days of repeated logs can already reveal a useful pattern. Require
  // recurrence across different days, scaling with the size of the sample.
  if (dayKeys.length < 3 || events.length < 5) return const [];
  final minDays = (dayKeys.length * 0.2).ceil().clamp(2, dayKeys.length);
  final candidates =
      daysByNearbyHalfHours.entries
          .map((entry) => MapEntry(entry.key, entry.value))
          .where((entry) => entry.value.length >= minDays)
          .toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

  final selectedSlots = <int>[];
  for (final candidate in candidates) {
    final tooClose = selectedSlots.any((selected) {
      final difference = (candidate.key - selected).abs();
      return math.min(difference, 48 - difference) <= 2;
    });
    if (!tooClose) selectedSlots.add(candidate.key);
    if (selectedSlots.length == 4) break;
  }

  selectedSlots.sort();
  return selectedSlots
      .map((slot) => SleepRoutineTime(_representativeMinute(slot, events)))
      .toList();
}

int _representativeMinute(int slot, List<BabyEvent> events) {
  final centerMinute = slot * 30;
  final samples = events
      .map((event) => event.startTime.hour * 60 + event.startTime.minute)
      .where((minute) {
        final difference = (minute - centerMinute).abs();
        return math.min(difference, 24 * 60 - difference) <= 45;
      })
      .toList();
  if (samples.isEmpty) return centerMinute % (24 * 60);

  var sinTotal = 0.0;
  var cosTotal = 0.0;
  for (final minute in samples) {
    final angle = minute / (24 * 60) * 2 * math.pi;
    sinTotal += math.sin(angle);
    cosTotal += math.cos(angle);
  }
  final angle = math.atan2(sinTotal, cosTotal);
  return ((angle / (2 * math.pi) * 24 * 60).round() + 24 * 60) % (24 * 60);
}
