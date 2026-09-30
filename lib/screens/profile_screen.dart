import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/baby.dart';
import '../providers/auth_provider.dart';
import '../providers/baby_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../utils/strings.dart';
import 'notification_settings_screen.dart';
import '../services/navigation_service.dart';
import '../services/paywall_service.dart';
import '../services/paywall_trigger_service.dart';
import '../services/purchase_service.dart';
import '../services/review_service.dart';
import '../widgets/bottom_sheets/bug_report_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showAddBaby = false;

  @override
  Widget build(BuildContext context) {
    final babyProvider = context.watch<BabyProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final strings = localeProvider.strings;
    final babies = babyProvider.babies;
    final currentBaby = babyProvider.currentBaby;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.profile),
        leading: GestureDetector(
          onTap: () => NavigationService.goToHome(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentBaby != null) _buildCurrentBabyCard(context, currentBaby, babyProvider, strings),
            const SizedBox(height: 20),
            _buildBabyList(context, babies, babyProvider, strings),
            const SizedBox(height: 20),
            _buildSettingsSection(context, localeProvider, strings),
            const SizedBox(height: 20),
            _buildAccountSection(context, strings),
            const SizedBox(height: 20),
            _buildSubscriptionSection(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBabyCard(
      BuildContext context, Baby baby, BabyProvider babyProvider, Strings strings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.sleepPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.sleepPurple.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                baby.name.isNotEmpty
                    ? baby.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.sleepPurple,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            baby.name,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            baby.ageLabel,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 4),
            Text(
              strings.bornDate(DateFormat('MMM d, yyyy', strings.pt ? 'pt_BR' : 'en').format(baby.dateOfBirth)),
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 13),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ProfileStat(
                value: '${baby.ageInWeeks}',
                label: strings.weeks,
              ),
              const SizedBox(width: 32),
              _ProfileStat(
                value: '${baby.ageInMonths}',
                label: strings.months,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditBabyDialog(context, baby, babyProvider),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(strings.editProfile),
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
        ],
      ),
    );
  }

  Widget _buildBabyList(
      BuildContext context, List<Baby> babies, BabyProvider babyProvider, Strings strings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.babies,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showAddBaby = !_showAddBaby),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sleepPurple.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.sleepPurple, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_showAddBaby) ...[
            _AddBabyForm(
              onSave: (name, dob) {
                babyProvider.addBaby(name, dob);
                setState(() => _showAddBaby = false);
              },
              onCancel: () => setState(() => _showAddBaby = false),
              strings: strings,
            ),
            const SizedBox(height: 12),
          ],
          ...babies.asMap().entries.map((entry) {
            final index = entry.key;
            final baby = entry.value;
            final isSelected = index == babyProvider.currentIndex;
            return GestureDetector(
              onTap: () {
                babyProvider.setCurrentBaby(index);
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.sleepPurple.withValues(alpha: 0.1)
                      : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.sleepPurple.withValues(alpha: 0.3)
                        : AppColors.cardBorder.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.sleepPurple.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          baby.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.sleepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            baby.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            baby.ageLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.sleepPurple, size: 22)
                    else
                      GestureDetector(
                        onTap: () => _confirmDeleteBaby(
                            context, babyProvider, baby),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline,
                              size: 16, color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, LocaleProvider localeProvider, Strings strings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.settings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _SettingsRow(
            icon: Icons.language_outlined,
            label: strings.language,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localeProvider.isPortuguese ? strings.portuguese : strings.english,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary, size: 20),
              ],
            ),
            onTap: () => _showLanguagePicker(context, localeProvider),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _SettingsRow(
            icon: Icons.notifications_outlined,
            label: strings.notifications,
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _SettingsRow(
            icon: Icons.bug_report_outlined,
            label: strings.reportBug,
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
            onTap: () => _showBugReportSheet(context),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _SettingsRow(
            icon: Icons.star_outline_rounded,
            label: strings.rateApp,
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
            onTap: () => ReviewService.requestReview(),
          ),
          if (kDebugMode) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            _SettingsRow(
              icon: Icons.science_outlined,
              label: 'Debug: resetar regras do paywall',
              trailing: const Icon(Icons.refresh_rounded,
                  color: AppColors.sleepPurple, size: 20),
              onTap: () => _debugResetPaywallRules(context),
            ),
          ],
        ],
      ),
    );
  }

  /// O throttle tem carencia de 1 dia e desliga apos 3 dispensas, o que
  /// torna o paywall automatico intestavel em tempo real sem isso.
  Future<void> _debugResetPaywallRules(BuildContext context) async {
    await PaywallTriggerService.debugReset();
    if (!context.mounted) return;
    final state = PaywallTriggerService.debugState;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paywall resetado\n'
          'dispensas=${state['dismiss_count']} '
          'eventos=${state['events_since_last']} '
          'intervalo=${state['required_interval_hours']}h',
        ),
        backgroundColor: AppColors.sleepPurple,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, Strings strings) {
    final authProvider = context.watch<AuthProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.account,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          if (authProvider.user?.email != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, size: 22, color: AppColors.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      authProvider.user!.email!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _SettingsRow(
            icon: Icons.logout_rounded,
            label: strings.logout,
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final strings = context.read<LocaleProvider>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.logout),
        content: Text(strings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(strings.logout),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sub.isPro
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: sub.isPro
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.cardBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sub.isPro ? Icons.workspace_premium_rounded : Icons.star_outline_rounded,
                color: sub.isPro ? AppColors.wakeYellow : AppColors.textTertiary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                strings.nestRoutinePro,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: sub.isPro ? AppColors.wakeYellow : AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              if (sub.isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    strings.proActive,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub.isPro ? strings.proUnlocked : strings.proUnlockCta,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: sub.isPro
                  ? _openCustomerCenter
                  : () => PaywallService.present(
                        context,
                        trigger: PaywallTriggerPoint.profileUpgrade,
                      ),
                icon: Icon(sub.isPro ? Icons.settings_rounded : Icons.star_rounded, size: 18),
                label: Text(sub.isPro ? strings.manageSubscription : strings.upgradeToPro),
                style: FilledButton.styleFrom(
                  backgroundColor: sub.isPro
                      ? AppColors.mediumPurple
                      : AppColors.sleepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (!sub.isPro) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _restorePurchases(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textTertiary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(strings.restorePurchases, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ],
      ),
    );
  }

  Future<void> _openCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

  Future<void> _restorePurchases(BuildContext context) async {
    final strings = context.read<LocaleProvider>().strings;
    try {
      await PurchaseService.restorePurchases();
      final isPro = await PurchaseService.checkProStatus();
      if (!context.mounted) return;
      context.read<SubscriptionProvider>().refresh();
      if (isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.purchasesRestored)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.noPurchasesFound)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
        ),
      );
    }
  }

  void _showEditBabyDialog(
      BuildContext context, Baby baby, BabyProvider babyProvider) {
    final nameController = TextEditingController(text: baby.name);

    showDialog(
      context: context,
      builder: (ctx) => _EditBabyDialog(
        baby: baby,
        babyProvider: babyProvider,
        nameController: nameController,
      ),
    );
  }

  void _confirmDeleteBaby(
      BuildContext context, BabyProvider babyProvider, Baby baby) {
    final strings = context.read<LocaleProvider>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.removeBaby),
        content: Text(strings.removeBabyConfirm(baby.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              babyProvider.removeBaby(baby.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(strings.remove),
          ),
        ],
      ),
    );
  }

  void _showBugReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BugReportSheet(),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
    final strings = context.read<LocaleProvider>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.language),
        content: RadioGroup<bool>(
          groupValue: localeProvider.isPortuguese,
          onChanged: (bool? isPortuguese) {
            localeProvider.setLocale(isPortuguese == true ? 'pt' : 'en');
            Navigator.pop(ctx);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(strings.english),
                leading: const Radio<bool>(
                  value: false,
                  activeColor: AppColors.sleepPurple,
                ),
              ),
              ListTile(
                title: Text(strings.portuguese),
                leading: const Radio<bool>(
                  value: true,
                  activeColor: AppColors.sleepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _AddBabyForm extends StatefulWidget {
  final void Function(String name, DateTime dateOfBirth) onSave;
  final VoidCallback onCancel;
  final Strings strings;

  const _AddBabyForm({required this.onSave, required this.onCancel, required this.strings});

  @override
  State<_AddBabyForm> createState() => _AddBabyFormState();
}

class _AddBabyFormState extends State<_AddBabyForm> {
  final _nameController = TextEditingController();
  DateTime _dob = DateTime.now().subtract(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: widget.strings.babysName,
              hintText: widget.strings.nameHint,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dob,
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365 * 3)),
                lastDate: DateTime.now(),
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
              if (picked != null) setState(() => _dob = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(widget.strings.dateOfBirth,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, yyyy', widget.strings.pt ? 'pt_BR' : 'en').format(_dob),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.strings.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      widget.onSave(_nameController.text.trim(), _dob);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sleepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.strings.addBaby),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditBabyDialog extends StatefulWidget {
  final Baby baby;
  final BabyProvider babyProvider;
  final TextEditingController nameController;

  const _EditBabyDialog({
    required this.baby,
    required this.babyProvider,
    required this.nameController,
  });

  @override
  State<_EditBabyDialog> createState() => _EditBabyDialogState();
}

class _EditBabyDialogState extends State<_EditBabyDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.baby.dateOfBirth;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.read<LocaleProvider>().strings;
    return AlertDialog(
      title: Text(strings.editProfile),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.nameController,
            decoration: InputDecoration(labelText: strings.name),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                lastDate: DateTime.now(),
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
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(DateFormat('MMM d, yyyy', strings.pt ? 'pt_BR' : 'en').format(_selectedDate)),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (widget.nameController.text.isNotEmpty) {
              widget.babyProvider.updateBaby(
                widget.baby.id,
                name: widget.nameController.text,
                dateOfBirth: _selectedDate,
              );
              Navigator.pop(context);
            }
          },
          child: Text(strings.save),
        ),
      ],
    );
  }
}
