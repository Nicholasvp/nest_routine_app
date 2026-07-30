import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_utils.dart';
import '../../utils/strings.dart';

class FeedSheet extends StatefulWidget {
  final BabyEvent? activeTimer;
  final BabyEvent? event;
  final void Function(DateTime startTime, FeedSide? feedSide) onStartNursing;
  final void Function(DateTime endTime, FeedSide? feedSide, {DateTime? startTime}) onStopNursing;
  final void Function(BabyEvent event) onLogFeed;
  final void Function(BabyEvent event)? onUpdateFeed;
  final void Function(FeedSide feedSide)? onTimerFeedSideChanged;

  const FeedSheet({
    super.key,
    this.activeTimer,
    this.event,
    required this.onStartNursing,
    required this.onStopNursing,
    required this.onLogFeed,
    this.onUpdateFeed,
    this.onTimerFeedSideChanged,
  });

  @override
  State<FeedSheet> createState() => _FeedSheetState();
}

class _FeedSheetState extends State<FeedSheet> {
  late FeedType _feedType;
  late FeedSide _feedSide;
  late int _durationMinutes;
  late int _volumeMl;
  late DateTime _feedStartTime;
  late DateTime _feedEndTime;
  bool _isManualTime = false;
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _feedType = widget.event!.feedType ?? FeedType.breast;
      _feedSide = widget.event!.feedSide ?? FeedSide.left;
      _durationMinutes = widget.event!.durationMinutes ?? 15;
      _volumeMl = widget.event!.volumeMl ?? 60;
      _feedStartTime = widget.event!.startTime;
      _feedEndTime = widget.event!.endTime ?? DateTime.now();
      _isManualTime = true;
    } else {
      _feedType = FeedType.breast;
      _feedSide = widget.activeTimer?.feedSide ?? FeedSide.left;
      _durationMinutes = 15;
      _volumeMl = 60;
      _feedStartTime = DateTime.now().subtract(const Duration(minutes: 15));
      _feedEndTime = DateTime.now();
    }
  }

  @override
  void didUpdateWidget(FeedSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTimer != oldWidget.activeTimer && widget.activeTimer != null) {
      _feedSide = widget.activeTimer!.feedSide ?? _feedSide;
    }
    if (widget.event != oldWidget.event && widget.event != null) {
      _feedSide = widget.event!.feedSide ?? _feedSide;
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
                  color: AppColors.feedOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_dining_outlined,
                    color: AppColors.feedOrange, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                widget.event != null ? strings.logFeed :
                  widget.activeTimer != null ? strings.nursingNow : strings.logFeed,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (widget.activeTimer != null) ...[
            _buildTimerDisplay(context),
            const SizedBox(height: 20),
            _buildSideSelector(context),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAdjustDialog,
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
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.onStopNursing(DateTime.now(), _feedSide);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: Text(strings.stopNursing,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.feedOrange,
                      side: BorderSide(color: AppColors.feedOrange.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (widget.event != null) ...[
            _buildEditMode(context, strings),
          ] else ...[
            _buildNewFeedMode(context, strings),
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
        color: AppColors.feedOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.feedOrange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            AppDateUtils.formatDuration(duration),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.feedOrange,
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

  void _showAdjustDialog() {
    final tr = context.read<LocaleProvider>().strings;
    DateTime adjustStart = widget.activeTimer!.startTime;
    DateTime adjustEnd = DateTime.now();
    final startLabel = tr.startTime;
    final endLabel = tr.endTime;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr.adjust),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimePicker(
                label: startLabel,
                time: adjustStart,
                onChanged: (t) => setDialogState(() => adjustStart = t),
              ),
              const SizedBox(height: 12),
              _TimePicker(
                label: endLabel,
                time: adjustEnd,
                onChanged: (t) => setDialogState(() => adjustEnd = t),
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
                widget.onStopNursing(adjustEnd, _feedSide, startTime: adjustStart);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(tr.confirm),
            ),
          ],
        ),
      ),
    );
  }

  void _setFeedSide(FeedSide side) {
    setState(() => _feedSide = side);
    if (widget.activeTimer != null) {
      widget.onTimerFeedSideChanged?.call(side);
    }
  }

  Widget _buildSideSelector(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    return Row(
      children: [
        Expanded(
          child: _SideButton(
            label: strings.left,
            selected: _feedSide == FeedSide.left,
            onTap: () => _setFeedSide(FeedSide.left),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SideButton(
            label: strings.right,
            selected: _feedSide == FeedSide.right,
            onTap: () => _setFeedSide(FeedSide.right),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SideButton(
            label: strings.both,
            selected: _feedSide == FeedSide.both,
            onTap: () => _setFeedSide(FeedSide.both),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(BuildContext context, Strings strings) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
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
                      label: strings.startTime,
                      time: _feedStartTime,
                      onChanged: (t) => setState(() => _feedStartTime = t),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward,
                        color: AppColors.textTertiary, size: 18),
                  ),
                  Expanded(
                    child: _TimePicker(
                      label: strings.endTime,
                      time: _feedEndTime,
                      onChanged: (t) => setState(() => _feedEndTime = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${strings.duration}: ${_feedEndTime.difference(_feedStartTime).inMinutes} min',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        _buildFeedTypeSelector(context),
        const SizedBox(height: 20),
        if (_feedType == FeedType.breast) ...[
          _buildSideSelector(context),
        ] else ...[
          _buildSlider(
            context,
            label: strings.volume,
            value: _volumeMl.toDouble(),
            min: 10,
            max: 300,
            divisions: 29,
            display: '$_volumeMl ml',
            onChanged: (v) => setState(() => _volumeMl = v.round()),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveEdit,
            icon: const Icon(Icons.check_circle_outlined, size: 20),
            label: Text(strings.logFeed,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.feedOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewFeedMode(BuildContext context, Strings strings) {
    return Column(
      children: [
        if (_isManualMode) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
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
                        label: strings.startTime,
                        time: _feedStartTime,
                        onChanged: (t) => setState(() => _feedStartTime = t),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward,
                          color: AppColors.textTertiary, size: 18),
                    ),
                    Expanded(
                      child: _TimePicker(
                        label: strings.endTime,
                        time: _feedEndTime,
                        onChanged: (t) => setState(() => _feedEndTime = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${strings.duration}: ${_feedEndTime.difference(_feedStartTime).inMinutes} min',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ] else ...[
          if (_isManualTime)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _TimePicker(
                label: strings.time,
                time: _feedStartTime,
                onChanged: (t) => setState(() => _feedStartTime = t),
              ),
            ),
          if (!_isManualTime)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _isManualTime = true),
                icon: const Icon(Icons.access_time_outlined, size: 16),
                label: Text(
                  strings.manualTimeEntry,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
        _buildFeedTypeSelector(context),
        const SizedBox(height: 20),
        if (_feedType == FeedType.breast) ...[
          _buildSideSelector(context),
          if (!_isManualMode) ...[
            const SizedBox(height: 20),
            _buildSlider(
              context,
              label: strings.duration,
              value: _durationMinutes.toDouble(),
              min: 1,
              max: _durationMinutes > 60 ? _durationMinutes.toDouble() : 60,
              display: '$_durationMinutes min',
              onChanged: (v) => setState(() => _durationMinutes = v.round()),
            ),
          ],
        ] else ...[
          _buildSlider(
            context,
            label: strings.volume,
            value: _volumeMl.toDouble(),
            min: 10,
            max: 300,
            divisions: 29,
            display: '$_volumeMl ml',
            onChanged: (v) => setState(() => _volumeMl = v.round()),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              widget.onStartNursing(DateTime.now(), null);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.play_circle_outlined, size: 20),
            label: Text(strings.babyStartedNursing,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.feedOrange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveNew,
            icon: const Icon(Icons.check_circle_outlined, size: 20),
            label: Text(strings.logFeed,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cardDark,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (!_isManualMode && !_isManualTime) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _isManualMode = true),
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
    );
  }

  Widget _buildFeedTypeSelector(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    return Row(
      children: [
        Expanded(
          child: _ChoiceChip(
            label: strings.breast,
            icon: Icons.favorite_outline,
            selected: _feedType == FeedType.breast,
            color: AppColors.feedOrange,
            onTap: () => setState(() => _feedType = FeedType.breast),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ChoiceChip(
            label: strings.bottle,
            icon: Icons.water_outlined,
            selected: _feedType == FeedType.bottle,
            color: AppColors.feedTerracotta,
            onTap: () => setState(() => _feedType = FeedType.bottle),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text(display,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.feedOrange,
            inactiveTrackColor: AppColors.feedOrange.withValues(alpha: 0.15),
            thumbColor: AppColors.feedOrange,
            overlayColor: AppColors.feedOrange.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions ?? (max - min).round().toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _saveNew() {
    final event = BabyEvent(
      id: '',
      babyId: '',
      type: EventType.feed,
      startTime: _feedStartTime,
      endTime: _isManualMode
          ? _feedEndTime
          : (_feedType == FeedType.breast
              ? _feedStartTime.add(Duration(minutes: _durationMinutes))
              : _feedStartTime),
      feedType: _feedType,
      feedSide: _feedType == FeedType.breast ? _feedSide : null,
      durationMinutes: _feedType == FeedType.breast
          ? (_isManualMode
              ? _feedEndTime.difference(_feedStartTime).inMinutes
              : _durationMinutes)
          : null,
      volumeMl: _feedType == FeedType.bottle ? _volumeMl : null,
    );
    widget.onLogFeed(event);
    Navigator.of(context).pop();
  }

  void _saveEdit() {
    if (widget.event != null && widget.onUpdateFeed != null) {
      final duration = _feedEndTime.difference(_feedStartTime).inMinutes;
      final updated = widget.event!.copyWith(
        startTime: _feedStartTime,
        endTime: _feedEndTime,
        feedType: _feedType,
        feedSide: _feedType == FeedType.breast ? _feedSide : null,
        durationMinutes: _feedType == FeedType.breast ? duration : null,
        volumeMl: _feedType == FeedType.bottle ? _volumeMl : null,
      );
      widget.onUpdateFeed!(updated);
      Navigator.of(context).pop();
    }
  }

  void _save() {
    if (widget.event != null && widget.onUpdateFeed != null) {
      _saveEdit();
    } else {
      _saveNew();
    }
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? color : AppColors.textTertiary,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SideButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.feedOrange.withValues(alpha: 0.15)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.feedOrange.withValues(alpha: 0.4)
                : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.feedOrange : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
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
                primary: AppColors.feedOrange,
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
      child: Row(
        children: [
          const Icon(Icons.access_time_outlined,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              Text(
                DateFormat('HH:mm').format(time),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}
