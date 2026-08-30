import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../utils/sleep_window.dart';
import '../utils/strings.dart';

class SleepWindowBattery extends StatefulWidget {
  final SleepBatteryCalculator calculator;

  const SleepWindowBattery({super.key, required this.calculator});

  @override
  State<SleepWindowBattery> createState() => _SleepWindowBatteryState();
}

class _SleepWindowBatteryState extends State<SleepWindowBattery>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SleepWindowBattery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.calculator.state == BatteryState.critical) {
      _blinkController.repeat(reverse: true);
    } else {
      _blinkController.stop();
      _blinkController.value = 0;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    final calc = widget.calculator;
    final state = calc.state;
    final pct = calc.batteryPercent;

    if (calc.isCurrentlySleeping) {
      return _buildSleepingState(context, strings);
    }

    if (calc.lastWakeUp == null) {
      return _buildNoDataState(context, strings);
    }

    final barColor = _batteryColor(state);
    final bgColor = AppColors.cardDark;
    final borderCol = AppColors.cardBorder;

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, _) {
        final blinkOpacity = state == BatteryState.critical
            ? (math.sin(_blinkAnimation.value * math.pi) > 0 ? 1.0 : 0.15)
            : 1.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: state == BatteryState.critical
                  ? AppColors.error.withValues(alpha: blinkOpacity * 0.5)
                  : borderCol,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.battery_charging_full_outlined,
                    size: 18,
                    color: barColor.withValues(alpha: blinkOpacity),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.sleepWindow,
                    style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${calc.elapsedMinutesSinceWake}min / ${calc.window.maxMinutes}min',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBatteryBar(context, pct, barColor, blinkOpacity),
              const SizedBox(height: 8),
              Text(
                _statusText(calc, strings),
                style: TextStyle(
                  color: barColor.withValues(alpha: blinkOpacity),
                  fontSize: 14,
                  fontWeight: state == BatteryState.critical
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusText(SleepBatteryCalculator calc, Strings strings) {
    final remaining = calc.minutesUntilCritical;
    if (remaining <= 0) {
      return strings.windowClosed;
    }
    if (remaining <= 15) {
      return strings.timeForNap(remaining);
    }
    if (remaining <= 30) {
      return strings.windowClosing(remaining);
    }
    return strings.awakeFor(calc.elapsedMinutesSinceWake);
  }

  Widget _buildBatteryBar(
      BuildContext context, double pct, Color color, double opacity) {
    final bgColor = AppColors.cardBorder;
    final segments = 10;
    final filledSegments = (pct * segments).round().clamp(0, segments);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: List.generate(segments, (i) {
            final isFilled = i < filledSegments;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: i > 0 ? 2 : 0,
                ),
                decoration: BoxDecoration(
                  color: isFilled
                      ? color.withValues(alpha: opacity)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSleepingState(
      BuildContext context, Strings strings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.sleepPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sleepPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_round,
                color: AppColors.sleepPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.sleeping_,
                style: const TextStyle(
                  color: AppColors.sleepPurple,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                strings.batteryRestoredOnWake,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(
      BuildContext context, Strings strings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.battery_unknown_outlined,
                color: AppColors.textTertiary, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.sleepWindow,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                strings.registerWakeToStart,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _batteryColor(BatteryState state) {
    switch (state) {
      case BatteryState.full:
        return AppColors.diaperTeal;
      case BatteryState.draining:
        return AppColors.wakeYellow;
      case BatteryState.warning:
        return AppColors.feedOrange;
      case BatteryState.critical:
        return AppColors.error;
    }
  }
}
