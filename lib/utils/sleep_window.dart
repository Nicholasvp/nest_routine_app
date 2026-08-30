class SleepWindow {
  final int minMinutes;
  final int maxMinutes;

  const SleepWindow({required this.minMinutes, required this.maxMinutes});

  String get label {
    if (minMinutes < 60 && maxMinutes < 60) {
      return '$minMinutes-$maxMinutes min';
    }
    return '${_hours(minMinutes)}-${_hours(maxMinutes)}';
  }

  String _hours(int m) => '${m ~/ 60}h${m % 60 > 0 ? " ${m % 60}min" : ""}';

  static SleepWindow forAgeMonths(int months) {
    if (months < 2) return const SleepWindow(minMinutes: 45, maxMinutes: 60);
    if (months < 5) return const SleepWindow(minMinutes: 90, maxMinutes: 120);
    if (months < 8) return const SleepWindow(minMinutes: 120, maxMinutes: 180);
    return const SleepWindow(minMinutes: 180, maxMinutes: 240);
  }
}

enum BatteryState { full, draining, warning, critical }

class SleepBatteryCalculator {
  final int ageMonths;
  final DateTime? lastWakeUp;
  final bool isCurrentlySleeping;

  SleepBatteryCalculator({
    required this.ageMonths,
    this.lastWakeUp,
    this.isCurrentlySleeping = false,
  });

  SleepWindow get window => SleepWindow.forAgeMonths(ageMonths);

  int get elapsedMinutesSinceWake {
    if (lastWakeUp == null) return 0;
    return DateTime.now().difference(lastWakeUp!).inMinutes.clamp(0, 99999);
  }

  double get batteryPercent {
    if (isCurrentlySleeping || lastWakeUp == null) return 1.0;
    return (1 - (elapsedMinutesSinceWake / window.maxMinutes)).clamp(0.0, 1.0);
  }

  BatteryState get state {
    if (isCurrentlySleeping || lastWakeUp == null) return BatteryState.full;
    final pct = batteryPercent;
    if (pct > 0.5) return BatteryState.full;
    if (pct > 0.25) return BatteryState.draining;
    if (pct > 0.0) return BatteryState.warning;
    return BatteryState.critical;
  }

  int get minutesUntilCritical {
    if (isCurrentlySleeping || lastWakeUp == null) return 0;
    return (window.maxMinutes - elapsedMinutesSinceWake).clamp(0, 999);
  }


}
