import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScrollWheelTimePicker extends StatelessWidget {
  final String label;
  final DateTime time;
  final ValueChanged<DateTime> onChanged;
  final Color accentColor;

  const ScrollWheelTimePicker({
    super.key,
    required this.label,
    required this.time,
    required this.onChanged,
    this.accentColor = AppColors.sleepPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildWheel(
                  itemCount: 24,
                  selectedIndex: time.hour,
                  onSelectedItemChanged: (index) {
                    onChanged(DateTime(
                      time.year,
                      time.month,
                      time.day,
                      index,
                      time.minute,
                    ));
                  },
                  labelBuilder: (index) => index.toString().padLeft(2, '0'),
                ),
              ),
              Text(':',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  )),
              Expanded(
                child: _buildWheel(
                  itemCount: 60,
                  selectedIndex: time.minute,
                  onSelectedItemChanged: (index) {
                    onChanged(DateTime(
                      time.year,
                      time.month,
                      time.day,
                      time.hour,
                      index,
                    ));
                  },
                  labelBuilder: (index) => index.toString().padLeft(2, '0'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWheel({
    required int itemCount,
    required int selectedIndex,
    required ValueChanged<int> onSelectedItemChanged,
    required String Function(int) labelBuilder,
  }) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedIndex),
      itemExtent: 40,
      onSelectedItemChanged: onSelectedItemChanged,
      backgroundColor: Colors.transparent,
      selectionOverlay: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      children: List.generate(itemCount, (index) {
        return Center(
          child: Text(
            labelBuilder(index),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }),
    );
  }
}

class ScrollWheelDurationPicker extends StatelessWidget {
  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;
  final Color accentColor;
  final int minMinutes;
  final int maxMinutes;

  const ScrollWheelDurationPicker({
    super.key,
    required this.label,
    required this.minutes,
    required this.onChanged,
    this.accentColor = AppColors.sleepPurple,
    this.minMinutes = 1,
    this.maxMinutes = 120,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = minutes.clamp(minMinutes, maxMinutes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: clamped - minMinutes,
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) =>
                      onChanged(index + minMinutes),
                  backgroundColor: Colors.transparent,
                  selectionOverlay: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  children: List.generate(maxMinutes - minMinutes + 1, (index) {
                    return Center(
                      child: Text(
                        '${index + minMinutes}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'min',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
