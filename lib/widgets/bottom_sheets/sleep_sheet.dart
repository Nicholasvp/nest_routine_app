import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_utils.dart';
import '../event_date_field.dart';
import '../event_success_toast.dart';
import '../scroll_wheel_time_picker.dart';

enum _NewSleepStep { choice, fellAsleep, manual }

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
  late DateTime _fellAsleepStart;
  _NewSleepStep _step = _NewSleepStep.choice;

  @override
  void initState() {
    super.initState();
    _fellAsleepStart = DateTime.now();
    if (widget.event != null && widget.event!.endTime != null) {
      _manualStart = widget.event!.startTime;
      _manualEnd = widget.event!.endTime!;
    } else {
      _manualStart = DateTime.now().subtract(const Duration(hours: 1));
      _manualEnd = DateTime.now();
    }
  }

  DateTime get _resolvedManualEnd {
    var end = _manualEnd;
    if (!end.isAfter(_manualStart)) {
      end = end.add(const Duration(days: 1));
    }
    return end;
  }

  void _setManualDate(DateTime date) {
    final delta = DateTime(date.year, date.month, date.day).difference(
      DateTime(_manualStart.year, _manualStart.month, _manualStart.day),
    );
    setState(() {
      _manualStart = _manualStart.add(delta);
      _manualEnd = _manualEnd.add(delta);
    });
  }

  DateTime _resolvedFellAsleepStart() {
    final now = DateTime.now();
    var start = DateTime(
      now.year,
      now.month,
      now.day,
      _fellAsleepStart.hour,
      _fellAsleepStart.minute,
    );
    if (start.isAfter(now)) {
      start = start.subtract(const Duration(days: 1));
    }
    return start;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    final isEditing = widget.event != null && widget.event!.endTime != null;
    final isTimer = widget.activeTimer != null;
    final showBack = !isEditing && !isTimer && _step != _NewSleepStep.choice;

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
              if (showBack) ...[
                IconButton(
                  onPressed: () => setState(() => _step = _NewSleepStep.choice),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                const SizedBox(width: 4),
              ] else ...[
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
              ],
              Expanded(
                child: Text(
                  isEditing
                      ? strings.adjustSleepTime
                      : isTimer
                          ? strings.sleepTimer
                          : _step == _NewSleepStep.fellAsleep
                              ? strings.babyFellAsleep
                              : _step == _NewSleepStep.manual
                                  ? strings.manualTimeEntry
                                  : strings.logSleep,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isEditing) ...[
            _buildManualInput(context),
          ] else if (isTimer) ...[
            _buildTimerDisplay(context),
            const SizedBox(height: 24),
            _buildManualInput(context),
          ] else ...[
            switch (_step) {
              _NewSleepStep.choice => _buildChoice(context),
              _NewSleepStep.fellAsleep => _buildFellAsleep(context),
              _NewSleepStep.manual => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickTimes(context),
                    const SizedBox(height: 16),
                    _buildManualInput(context),
                  ],
                ),
            },
          ],
        ],
      ),
    );
  }

  Widget _buildChoice(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ChoiceOption(
          icon: Icons.nightlight_round,
          label: strings.babyFellAsleep,
          onTap: () => setState(() {
            _fellAsleepStart = DateTime.now();
            _step = _NewSleepStep.fellAsleep;
          }),
        ),
        const SizedBox(height: 12),
        _ChoiceOption(
          icon: Icons.schedule_rounded,
          label: strings.manualTimeEntry,
          onTap: () => setState(() => _step = _NewSleepStep.manual),
        ),
      ],
    );
  }

  Widget _buildFellAsleep(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    final start = _resolvedFellAsleepStart();
    final duration = DateTime.now().difference(start);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ScrollWheelTimePicker(
                label: strings.fellAsleep,
                time: _fellAsleepStart,
                onChanged: (t) => setState(() => _fellAsleepStart = t),
                accentColor: AppColors.sleepPurple,
              ),
              const SizedBox(height: 12),
              Text(
                AppDateUtils.formatDuration(duration),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.sleepPurple,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.sinceTime(AppDateUtils.formatTimeAmPm(start,
                    isPt: strings.pt)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            widget.onStartSleep(_resolvedFellAsleepStart());
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
    );
  }

  Widget _buildTimerDisplay(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    final duration = Duration(
      microseconds: DateTime.now()
          .difference(widget.activeTimer!.startTime)
          .inMicroseconds
          .clamp(0, 1 << 62),
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
            strings.sinceTime(AppDateUtils.formatTimeAmPm(
                widget.activeTimer!.startTime,
                isPt: strings.pt)),
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
                  final startTime =
                      DateTime.now().subtract(Duration(minutes: minutes));
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
          EventDateField(
            label: strings.date,
            date: _manualStart,
            onChanged: _setManualDate,
            accentColor: AppColors.sleepPurple,
            isPt: strings.pt,
          ),
          const SizedBox(height: 12),
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
                  widget.onStopSleep(_resolvedManualEnd);
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
                      endTime: _resolvedManualEnd,
                    ));
                    Navigator.of(context).pop();
                    EventSuccessToast.show(
                      context,
                      icon: Icons.nightlight_round,
                      color: AppColors.sleepPurple,
                      title: strings.adjustSleepTime,
                      subtitle: 'Sleep updated',
                    );
                  } else if (widget.onQuickLog != null) {
                    widget.onQuickLog!(_manualStart, _resolvedManualEnd);
                    Navigator.of(context).pop();
                    EventSuccessToast.show(
                      context,
                      icon: Icons.nightlight_round,
                      color: AppColors.sleepPurple,
                      title: strings.logSleep,
                      subtitle: 'Sleep logged',
                    );
                  } else {
                    widget.onStartSleep(_manualStart);
                    widget.onStopSleep(_resolvedManualEnd);
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

class _ChoiceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChoiceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sleepPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.sleepPurple, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
