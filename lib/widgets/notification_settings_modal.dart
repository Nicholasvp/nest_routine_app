import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

class NotificationSettingsModal extends StatelessWidget {
  const NotificationSettingsModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const NotificationSettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final strings = context.watch<LocaleProvider>().strings;
    final settings = provider.settings;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.sleepPurple.withValues(alpha: 0.3),
          ),
        ),
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
                Icons.notifications_active_outlined,
                color: AppColors.sleepPurple,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.notificationSettings,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.enableSmartNotifications,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sleepPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.sleepPurple.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  _NotificationToggle(
                    label: strings.nextSleepReminderDesc,
                    value: settings.sleepEnabled,
                    onChanged: (value) => provider.updateSleepEnabled(value),
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _NotificationToggle(
                    label: strings.nextFeedReminderDesc,
                    value: settings.feedEnabled,
                    onChanged: (value) => provider.updateFeedEnabled(value),
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _NotificationToggle(
                    label: strings.sleepWindowReminderDesc,
                    value: settings.sleepWindowEnabled,
                    onChanged: (value) =>
                        provider.updateSleepWindowEnabled(value),
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _NotificationToggle(
                    label: strings.peeReminderDesc,
                    value: settings.diaperPeeEnabled,
                    onChanged: (value) =>
                        provider.updateDiaperPeeEnabled(value),
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _NotificationToggle(
                    label: strings.poopReminderDesc,
                    value: settings.diaperPoopEnabled,
                    onChanged: (value) =>
                        provider.updateDiaperPoopEnabled(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sleepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  strings.close,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.sleepPurple,
          ),
        ],
      ),
    );
  }
}
