import 'package:flutter_test/flutter_test.dart';
import 'package:nestroutine/models/event.dart';
import 'package:nestroutine/utils/prediction_engine.dart';

List<int> computeScheduledAdvanceMinutes({
  required DateTime predictedTime,
  required DateTime now,
  List<int> advanceMinutes = const [15, 10, 5],
}) {
  final scheduled = <int>[];
  if (predictedTime.isAfter(now)) {
    for (final minutes in advanceMinutes) {
      final scheduledTime = predictedTime.subtract(Duration(minutes: minutes));
      if (!scheduledTime.isBefore(now)) {
        scheduled.add(minutes);
      }
    }
  }
  return scheduled;
}

bool shouldFireImmediateNotification({
  required DateTime predictedTime,
  required DateTime now,
}) {
  return predictedTime.isBefore(now) || predictedTime.isAtSameMomentAs(now);
}

void main() {
  group('Sleep notification scheduling logic', () {
    test('3 notifications when predicted time is 20+ min away', () {
      final now = DateTime(2026, 8, 30, 14, 0);
      final predicted = DateTime(2026, 8, 30, 14, 30);

      final result = computeScheduledAdvanceMinutes(
        predictedTime: predicted,
        now: now,
      );

      expect(result, [15, 10, 5]);
    });

    test('2 notifications when 15min would be in the past', () {
      final now = DateTime(2026, 8, 30, 14, 18);
      final predicted = DateTime(2026, 8, 30, 14, 30);

      final result = computeScheduledAdvanceMinutes(
        predictedTime: predicted,
        now: now,
      );

      expect(result, [10, 5]);
    });

    test('1 notification when only 5min is still in the future', () {
      final now = DateTime(2026, 8, 30, 14, 24);
      final predicted = DateTime(2026, 8, 30, 14, 30);

      final result = computeScheduledAdvanceMinutes(
        predictedTime: predicted,
        now: now,
      );

      expect(result, [5]);
    });

    test('0 advance notifications when predicted time is now', () {
      final now = DateTime(2026, 8, 30, 14, 30);
      final predicted = DateTime(2026, 8, 30, 14, 30);

      final result = computeScheduledAdvanceMinutes(
        predictedTime: predicted,
        now: now,
      );

      expect(result, isEmpty);
    });

    test('immediate notification when predicted time is in the past', () {
      final now = DateTime(2026, 8, 30, 14, 35);
      final predicted = DateTime(2026, 8, 30, 14, 30);

      expect(shouldFireImmediateNotification(predictedTime: predicted, now: now), isTrue);
    });

    test('no immediate notification when predicted time is in the future', () {
      final now = DateTime(2026, 8, 30, 14, 0);
      final predicted = DateTime(2026, 8, 30, 14, 30);

      expect(shouldFireImmediateNotification(predictedTime: predicted, now: now), isFalse);
    });

    test('prediction engine returns a time for sleep events', () {
      final now = DateTime.now();
      final events = [
        BabyEvent(
          id: '1',
          babyId: 'baby1',
          type: EventType.sleep,
          startTime: now.subtract(const Duration(hours: 3)),
          endTime: now.subtract(const Duration(hours: 2)),
        ),
        BabyEvent(
          id: '2',
          babyId: 'baby1',
          type: EventType.sleep,
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now,
        ),
      ];

      final prediction = PredictionEngine.predictNextSleep(events);
      expect(prediction.predictedTime, isNotNull);
      expect(prediction.predictedTime!.isAfter(now), isTrue);
    });

    test('prediction engine returns null when baby is sleeping', () {
      final now = DateTime.now();
      final events = [
        BabyEvent(
          id: '1',
          babyId: 'baby1',
          type: EventType.sleep,
          startTime: now.subtract(const Duration(hours: 3)),
          endTime: now.subtract(const Duration(hours: 2)),
        ),
        BabyEvent(
          id: '2',
          babyId: 'baby1',
          type: EventType.sleep,
          startTime: now.subtract(const Duration(minutes: 30)),
          endTime: null,
        ),
      ];

      final prediction = PredictionEngine.predictNextSleep(events);
      expect(prediction.predictedTime, isNull);
    });

    test('full flow: prediction + scheduling produces correct advance list', () {
      final now = DateTime.now();
      final wakeUp = now.subtract(const Duration(hours: 1));
      final events = [
        BabyEvent(
          id: '1',
          babyId: 'baby1',
          type: EventType.sleep,
          startTime: wakeUp.subtract(const Duration(hours: 2)),
          endTime: wakeUp,
        ),
      ];

      final prediction = PredictionEngine.predictNextSleep(events);
      expect(prediction.predictedTime, isNotNull);

      final scheduled = computeScheduledAdvanceMinutes(
        predictedTime: prediction.predictedTime!,
        now: now,
      );

      expect(scheduled, isNotEmpty);
      expect(scheduled.length, lessThanOrEqualTo(3));
      expect(scheduled, contains(5));
    });
  });
}
