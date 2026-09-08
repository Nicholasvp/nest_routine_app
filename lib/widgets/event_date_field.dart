import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class EventDateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final Color accentColor;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isPt;

  const EventDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.accentColor = AppColors.sleepPurple,
    this.firstDate,
    this.lastDate,
    this.isPt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 18, color: accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEE, MMM d, yyyy', isPt ? 'pt_BR' : 'en')
                        .format(date),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final min = firstDate ?? now.subtract(const Duration(days: 365));
    final max = lastDate ?? DateTime(now.year, now.month, now.day);
    final initial = date.isBefore(min)
        ? min
        : date.isAfter(max)
            ? max
            : date;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: min,
      lastDate: max,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: accentColor,
            surface: AppColors.darkPurple,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }
}
