import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../event_success_toast.dart';
import '../scroll_wheel_time_picker.dart';

class DiaperSheet extends StatefulWidget {
  final BabyEvent? event;
  final bool defaultPee;
  final bool defaultPoop;
  final void Function(BabyEvent event) onLogDiaper;
  final void Function(BabyEvent event)? onUpdateDiaper;

  const DiaperSheet({
    super.key,
    this.event,
    this.defaultPee = true,
    this.defaultPoop = false,
    required this.onLogDiaper,
    this.onUpdateDiaper,
  });

  @override
  State<DiaperSheet> createState() => _DiaperSheetState();
}

class _DiaperSheetState extends State<DiaperSheet> {
  late bool _hasPee;
  late bool _hasPoop;
  late DiaperTexture? _texture;
  bool _showDetails = false;
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _hasPee = widget.event!.hasPee;
      _hasPoop = widget.event!.hasPoop;
      _texture = widget.event!.diaperTexture;
      _showDetails = _texture != null;
      _selectedTime = widget.event!.startTime;
    } else {
      _hasPee = widget.defaultPee;
      _hasPoop = widget.defaultPoop;
      _texture = null;
      _selectedTime = DateTime.now();
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.diaperTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.baby_changing_station_outlined,
                    color: AppColors.diaperTeal, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                strings.logDiaper,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DiaperTypeButton(
                  icon: Icons.water_drop_outlined,
                  label: strings.pee,
                  color: AppColors.wakeYellow,
                  selected: _hasPee,
                  onTap: () => setState(() => _hasPee = !_hasPee),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiaperTypeButton(
                  icon: Icons.circle_outlined,
                  label: strings.poop,
                  color: AppColors.diaperTeal,
                  selected: _hasPoop,
                  onTap: () => setState(() => _hasPoop = !_hasPoop),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimePicker(context),
          const SizedBox(height: 20),
          if (!_showDetails)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _showDetails = true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(strings.addDetails,
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
          if (_showDetails) _buildTextureSelector(context),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outlined, size: 20),
              label: Text(strings.logDiaper,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.diaperTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextureSelector(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.texture,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: DiaperTexture.values.map((texture) {
            final labels = {
              DiaperTexture.normal: strings.normal,
              DiaperTexture.soft: strings.soft,
              DiaperTexture.liquid: strings.liquid,
              DiaperTexture.dry: strings.dry,
            };
            return FilterChip(
              label: Text(labels[texture]!),
              selected: _texture == texture,
              onSelected: (s) =>
                  setState(() => _texture = s ? texture : null),
              selectedColor: AppColors.diaperTeal.withValues(alpha: 0.2),
              checkmarkColor: AppColors.diaperTeal,
              backgroundColor: AppColors.cardDark,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _showDetails = false),
          child: Text(
            strings.hideDetails,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    return ScrollWheelTimePicker(
      label: strings.time,
      time: _selectedTime,
      onChanged: (t) => setState(() => _selectedTime = t),
      accentColor: AppColors.diaperTeal,
    );
  }

  void _save() {
    if (widget.event != null && widget.onUpdateDiaper != null) {
      final updated = widget.event!.copyWith(
        hasPee: _hasPee,
        hasPoop: _hasPoop,
        diaperTexture: _texture,
        startTime: _selectedTime,
      );
      widget.onUpdateDiaper!(updated);
      Navigator.of(context).pop();
      EventSuccessToast.show(
        context,
        icon: Icons.baby_changing_station_outlined,
        color: AppColors.diaperTeal,
        title: 'Diaper updated',
        subtitle: _getDiaperLabel(),
      );
    } else {
      final event = BabyEvent(
        id: '',
        babyId: '',
        type: _hasPee && _hasPoop
            ? EventType.pee
            : _hasPee
                ? EventType.pee
                : EventType.poop,
        startTime: _selectedTime,
        hasPee: _hasPee,
        hasPoop: _hasPoop,
        diaperTexture: _texture,
      );
      widget.onLogDiaper(event);
      Navigator.of(context).pop();
      EventSuccessToast.show(
        context,
        icon: Icons.baby_changing_station_outlined,
        color: AppColors.diaperTeal,
        title: 'Diaper logged',
        subtitle: _getDiaperLabel(),
      );
    }
  }

  String _getDiaperLabel() {
    if (_hasPee && _hasPoop) return 'Pee & Poop';
    if (_hasPee) return 'Pee';
    return 'Poop';
  }
}

class _DiaperTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DiaperTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            Icon(icon,
                color: selected ? color : AppColors.textTertiary, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
