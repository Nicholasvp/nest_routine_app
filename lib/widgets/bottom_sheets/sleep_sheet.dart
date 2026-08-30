import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_utils.dart';
import '../event_success_toast.dart';
import '../scroll_wheel_time_picker.dart';

class SleepSheet extends StatefulWidget {
  final BabyEvent? activeTimer;
  final BabyEvent? event;
  final void Function(DateTime startTime) onStartSleep;
  final void Function(DateTime endTime) onStopSleep;
  final void Function(BabyEvent event)? onUpdateSleep;
  final void Function(DateTime startTime, DateTime endTime)? onQuickLog;

  const SleepSheet({
    super.key,
    this.activeTimer,
    this.event,
    required this.onStartSleep,
    required this.onStopSleep,
    this.onUpdateSleep,
    this.onQuickLog,
  });

  @override
  State<SleepSheet> createState() => _SleepSheetState();
}

class _SleepSheetState extends State<SleepSheet> {
  late DateTime _manualStart;
  late DateTime _manualEnd;

  @override
  void initState() {
    super.initState();
    if (widget.event != null && widget.event!.endTime != null) {
      _manualStart = widget.event!.startTime;
      _manualEnd = widget.event!.endTime!;
    } else {
      _manualStart = DateTime.now().subtract(const Duration(hours: 1));
      _manualEnd = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.darkPurple,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sleepPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nightlight_round,
                    color: AppColors.sleepPurple, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                widget.event != null ? strings.adjustSleepTime :
                  widget.activeTimer != null ? strings.sleepTimer : strings.logSleep,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (widget.event != null && widget.event!.endTime != null) ...[
            _buildManualInput(context),
          ] else if (widget.activeTimer != null) ...[
            _buildTimerDisplay(context),
            const SizedBox(height: 24),
            _buildManualInput(context),
          ] else ...[
            _buildQuickTimes(context),
            const SizedBox(height: 16),
            _buildManualInput(context),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                widget.onStartSleep(DateTime.now());
                Navigator.of(context).pop();
                EventSuccessToast.show(
                  context,
                  icon: Icons.nightlight_round,
                  color: AppColors.sleepPurple,
                  title: strings.babyFellAsleep,
                  subtitle: 'Sleep timer started',
                );
              },
              icon: const Icon(Icons.nightlight_round, size: 20),
              label: Text(strings.babyFellAsleep,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sleepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    final duration = Duration(
      microseconds: DateTime.now().difference(widget.activeTimer!.startTime).inMicroseconds.clamp(0, 1 << 62),
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.sleepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sleepPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            AppDateUtils.formatDuration(duration),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.sleepPurple,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.sinceTime(AppDateUtils.formatTimeAmPm(widget.activeTimer!.startTime, isPt: strings.pt)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTimes(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    final quickTimes = [30, 60, 90, 120];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.quickDuration,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                )),
        const SizedBox(height: 8),
        Row(
          children: quickTimes.map((minutes) {
            final isSelected = false;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${minutes}min'),
                selected: isSelected,
                onSelected: (_) {
                  final startTime = DateTime.now()
                      .subtract(Duration(minutes: minutes));
                  final endTime = DateTime.now();
                  if (widget.onQuickLog != null) {
                    widget.onQuickLog!(startTime, endTime);
                  } else {
                    widget.onStartSleep(startTime);
                    widget.onStopSleep(endTime);
                  }
                  Navigator.of(context).pop();
                },
                selectedColor: AppColors.sleepPurple.withValues(alpha: 0.2),
                checkmarkColor: AppColors.sleepPurple,
                backgroundColor: AppColors.cardDark,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildManualInput(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ScrollWheelTimePicker(
                  label: strings.fellAsleep,
                  time: _manualStart,
                  onChanged: (t) => setState(() => _manualStart = t),
                  accentColor: AppColors.sleepPurple,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    color: AppColors.textTertiary, size: 18),
              ),
              Expanded(
                child: ScrollWheelTimePicker(
                  label: strings.wokeUp,
                  time: _manualEnd,
                  onChanged: (t) => setState(() => _manualEnd = t),
                  accentColor: AppColors.sleepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.activeTimer != null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  widget.onStopSleep(_manualEnd);
                  Navigator.of(context).pop();
                  EventSuccessToast.show(
                    context,
                    icon: Icons.nightlight_round,
                    color: AppColors.wakeYellow,
                    title: strings.wakeUp,
                    subtitle: 'Sleep logged',
                  );
                },
                icon: const Icon(Icons.stop_circle_outlined, size: 20),
                label: Text(strings.wakeUp,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.wakeYellow,
                  foregroundColor: AppColors.deepNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (widget.event != null && widget.onUpdateSleep != null) {
                    widget.onUpdateSleep!(widget.event!.copyWith(
                      startTime: _manualStart,
                      endTime: _manualEnd,
                    ));
                    Navigator.of(context).pop();
                    EventSuccessToast.show(
                      context,
                      icon: Icons.nightlight_round,
                      color: AppColors.sleepPurple,
                      title: strings.adjustSleepTime,
                      subtitle: 'Sleep updated',
                    );
                  } else {
                    widget.onStartSleep(_manualStart);
                    widget.onStopSleep(_manualEnd);
                    Navigator.of(context).pop();
                    EventSuccessToast.show(
                      context,
                      icon: Icons.nightlight_round,
                      color: AppColors.sleepPurple,
                      title: strings.logSleep,
                      subtitle: 'Sleep logged',
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sleepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(strings.save,
                     style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


