import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_utils.dart';

class SleepSheet extends StatefulWidget {
  final BabyEvent? activeTimer;
  final BabyEvent? event;
  final void Function(DateTime startTime) onStartSleep;
  final void Function(DateTime endTime) onStopSleep;
  final void Function(BabyEvent event)? onUpdateSleep;

  const SleepSheet({
    super.key,
    this.activeTimer,
    this.event,
    required this.onStartSleep,
    required this.onStopSleep,
    this.onUpdateSleep,
  });

  @override
  State<SleepSheet> createState() => _SleepSheetState();
}

class _SleepSheetState extends State<SleepSheet> {
  late DateTime _manualStart;
  late DateTime _manualEnd;
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null && widget.event!.endTime != null) {
      _manualStart = widget.event!.startTime;
      _manualEnd = widget.event!.endTime!;
      _isManualMode = true;
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showManualAdjust,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(strings.adjust),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.onStopSleep(DateTime.now());
                      Navigator.of(context).pop();
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
              ],
            ),
          ] else ...[
            _buildQuickTimes(context),
            const SizedBox(height: 16),
            if (_isManualMode) _buildManualInput(context),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                widget.onStartSleep(DateTime.now());
                Navigator.of(context).pop();
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

          if (!_isManualMode && widget.activeTimer == null && widget.event == null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isManualMode = !_isManualMode),
              child: Text(
                strings.manualTimeEntry,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
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
    final duration = DateTime.now().difference(widget.activeTimer!.startTime);
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
            strings.sinceTime(AppDateUtils.formatTimeAmPm(widget.activeTimer!.startTime)),
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
                  final endTime = DateTime.now()
                      .subtract(Duration(minutes: minutes));
                  widget.onStartSleep(
                      endTime.subtract(const Duration(minutes: 5)));
                  widget.onStopSleep(endTime);
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
                child: _TimePicker(
                  label: strings.fellAsleep,
                  time: _manualStart,
                  onChanged: (t) => setState(() => _manualStart = t),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    color: AppColors.textTertiary, size: 18),
              ),
              Expanded(
                child: _TimePicker(
                  label: strings.wokeUp,
                  time: _manualEnd,
                  onChanged: (t) => setState(() => _manualEnd = t),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                } else {
                  widget.onStartSleep(_manualStart);
                  widget.onStopSleep(_manualEnd);
                  Navigator.of(context).pop();
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
      ),
    );
  }

  void _showManualAdjust() {
    final tr = context.read<LocaleProvider>().strings;
    final endTime = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.adjustSleepTime),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TimePicker(
              label: tr.fellAsleep,
              time: widget.activeTimer!.startTime,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            _TimePicker(
              label: tr.wokeUp,
              time: endTime,
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () {
              widget.onStopSleep(endTime);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(tr.confirm),
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final DateTime time;
  final ValueChanged<DateTime> onChanged;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(time),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.sleepPurple,
                surface: AppColors.darkPurple,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          final dt = DateTime(
            time.year,
            time.month,
            time.day,
            picked.hour,
            picked.minute,
          );
          onChanged(dt);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkPurple,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              DateFormat('HH:mm').format(time),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
