import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../providers/notification_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';
import '../utils/strings.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermission();
    });
  }

  void _checkPermission() {
    final provider = context.read<NotificationProvider>();
    if (!provider.permissionGranted) {
      provider.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final strings = localeProvider.strings;
    final isPro = context.watch<SubscriptionProvider>().isPro;

    if (!isPro) {
      return _buildProGate(context, provider, strings);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.notificationSettings),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
      body: _buildBody(provider, strings),
    );
  }

  Widget _buildProGate(BuildContext context, NotificationProvider provider, Strings strings) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.notificationSettings),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Opacity(
                opacity: 0.5,
                child: _buildBody(provider, strings),
              ),
            ),
          ),
          Center(
            child: _buildProOverlayCard(context, strings),
          ),
        ],
      ),
    );
  }

  Widget _buildProOverlayCard(BuildContext context, Strings strings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.sleepPurple.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
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
              Icons.notifications_off_outlined,
              color: AppColors.sleepPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.unlockNotifications,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.unlockNotificationsDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _openPaywall(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sleepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                strings.upgradeToPro,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaywall(BuildContext context) async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        PurchaseService.proEntitlementId,
        displayCloseButton: true,
      );
      if (!context.mounted) return;
      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        context.read<SubscriptionProvider>().refresh();
      }
    } catch (e) {
      debugPrint('[NotificationSettingsScreen] Paywall error: $e');
    }
  }

  Widget _buildBody(NotificationProvider provider, Strings strings) {
    final settings = provider.settings;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!provider.permissionGranted) _buildPermissionBanner(strings),
          _buildSection(
            strings.appReminder,
            [
              _SettingsToggle(
                label: strings.appReminderDesc,
                value: settings.appReminderEnabled,
                onChanged: (value) => provider.updateAppReminder(value),
              ),
              if (settings.appReminderEnabled) ...[
                const Divider(height: 1, color: AppColors.cardBorder),
                _TimePickerRow(
                  label: strings.appReminderTime,
                  hour: settings.appReminderHour,
                  minute: settings.appReminderMinute,
                  onChanged: (hour, minute) =>
                      provider.updateAppReminderTime(hour, minute),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            strings.predictions,
            [
              _SettingsToggle(
                label: strings.nextSleepReminderDesc,
                value: settings.sleepEnabled,
                onChanged: (value) => provider.updateSleepEnabled(value),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              _SettingsToggle(
                label: strings.nextFeedReminderDesc,
                value: settings.feedEnabled,
                onChanged: (value) => provider.updateFeedEnabled(value),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              _SettingsToggle(
                label: strings.sleepWindowReminderDesc,
                value: settings.sleepWindowEnabled,
                onChanged: (value) =>
                    provider.updateSleepWindowEnabled(value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            strings.diaperCheckReminder,
            [
              _SettingsToggle(
                label: strings.peeReminderDesc,
                value: settings.diaperPeeEnabled,
                onChanged: (value) => provider.updateDiaperPeeEnabled(value),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              _SettingsToggle(
                label: strings.poopReminderDesc,
                value: settings.diaperPoopEnabled,
                onChanged: (value) =>
                    provider.updateDiaperPoopEnabled(value),
              ),
              if (settings.diaperPeeEnabled ||
                  settings.diaperPoopEnabled) ...[
                const Divider(height: 1, color: AppColors.cardBorder),
                _IntervalPickerRow(
                  label: strings.diaperInterval,
                  intervalHours: settings.diaperIntervalHours,
                  onChanged: (hours) => provider.updateDiaperInterval(hours),
                  strings: strings,
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(Strings strings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.permissionRequired,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  strings.permissionRequiredDesc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                context.read<NotificationProvider>().requestPermission(),
            child: Text(strings.grantPermission),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            activeColor: AppColors.sleepPurple,
          ),
        ],
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final Function(int hour, int minute) onChanged;

  const _TimePickerRow({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showTimePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.sleepPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppColors.sleepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
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
      onChanged(picked.hour, picked.minute);
    }
  }
}

class _IntervalPickerRow extends StatelessWidget {
  final String label;
  final int intervalHours;
  final ValueChanged<int> onChanged;
  final Strings strings;

  const _IntervalPickerRow({
    required this.label,
    required this.intervalHours,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          DropdownButton<int>(
            value: intervalHours,
            dropdownColor: AppColors.cardDark,
            style: const TextStyle(color: AppColors.textPrimary),
            underline: const SizedBox(),
            items: [1, 2, 3, 4].map((hours) {
              return DropdownMenuItem(
                value: hours,
                child: Text(strings.everyHours(hours)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
