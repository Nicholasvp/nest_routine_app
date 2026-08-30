import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

class WakeUpModal extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const WakeUpModal({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  static void show(BuildContext context, {required VoidCallback onYes, required VoidCallback onNo}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WakeUpModal(onYes: onYes, onNo: onNo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;

    return Dialog(
      backgroundColor: AppColors.darkPurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.sleepPurple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: AppColors.sleepPurple,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.wakeCheckModalTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onYes();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.wakeYellow,
                  foregroundColor: AppColors.deepNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  strings.wakeCheckYes,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onNo();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sleepPurple,
                  side: const BorderSide(color: AppColors.sleepPurple),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  strings.wakeCheckNo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
