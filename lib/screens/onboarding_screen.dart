import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/baby_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';
import '../utils/storage_service.dart';
import '../utils/strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  DateTime _dob = DateTime.now().subtract(const Duration(days: 30));
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildIntroPage(context, strings),
                  _buildFeaturesPage(context, strings),
                  _buildTutorialPage(context, strings),
                  _buildSetupPage(context, strings),
                ],
              ),
            ),
            _buildBottomNavigation(context, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage(BuildContext context, Strings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  AppColors.sleepPurple,
                  AppColors.darkPurple,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sleepPurple.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.nightlight_round,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            strings.appName,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.understandYourBaby,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _LanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(BuildContext context, Strings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FeatureItem(
            icon: Icons.nightlight_round,
            color: AppColors.sleepPurple,
            title: strings.wePredictSleep,
            description: strings.wePredictSleepDesc,
          ),
          const SizedBox(height: 28),
          _FeatureItem(
            icon: Icons.touch_app_rounded,
            color: AppColors.feedOrange,
            title: strings.logOneTap,
            description: strings.logOneTapDesc,
          ),
          const SizedBox(height: 28),
          _FeatureItem(
            icon: Icons.notifications_active_outlined,
            color: AppColors.diaperTeal,
            title: strings.notificationsRightTime,
            description: strings.notificationsRightTimeDesc,
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialPage(BuildContext context, Strings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tutorialTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tutorialSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _TutorialItem(
            icon: Icons.nightlight_round,
            color: AppColors.sleepPurple,
            title: strings.tutorialSleepTitle,
            description: strings.tutorialSleepDesc,
          ),
          const SizedBox(height: 24),
          _TutorialItem(
            icon: Icons.restaurant_outlined,
            color: AppColors.feedOrange,
            title: strings.tutorialFeedTitle,
            description: strings.tutorialFeedDesc,
          ),
          const SizedBox(height: 24),
          _TutorialItem(
            icon: Icons.water_drop_outlined,
            color: AppColors.diaperTeal,
            title: strings.tutorialDiaperTitle,
            description: strings.tutorialDiaperDesc,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage(BuildContext context, Strings strings) {
    final isPt = context.read<LocaleProvider>().isPortuguese;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.setupYourBaby,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.setupSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: strings.babysName,
              hintText: strings.nameHint,
              prefixIcon: const Icon(Icons.baby_changing_station_outlined,
                  color: AppColors.textTertiary),
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
            autofocus: true,
          ),
          const SizedBox(height: 20),
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: AppColors.textTertiary, size: 24),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.dateOfBirth,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMMM d, yyyy', isPt ? 'pt_BR' : 'en').format(_dob),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, Strings strings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.sleepPurple
                      : AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _currentPage < 3
                  ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                   : () => _completeOnboarding(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sleepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
              child: Text(
                _currentPage < 3 ? strings.next : strings.getStarted,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (_currentPage < 3)
            TextButton(
              onPressed: () => _completeOnboarding(),
              child: Text(
                strings.skipSetup,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    _isCompleting = true;

    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      context.read<BabyProvider>().addBaby(name, _dob);
    }
    await StorageService.setOnboardingCompleteFor(
        context.read<AuthProvider>().user?.id, true);
    if (!context.mounted) return;

    await _presentPaywall();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _presentPaywall() async {
    debugPrint('[OnboardingScreen] Opening RevenueCat paywall');
    try {
      final isPt = context.read<LocaleProvider>().isPortuguese;
      await PurchaseService.setPreferredLocale(isPt);
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        PurchaseService.proEntitlementId,
        displayCloseButton: true,
      );
      debugPrint('[OnboardingScreen] Paywall result: $result');
      if (!mounted) return;
      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        context.read<SubscriptionProvider>().refresh();
      }
    } catch (e) {
      debugPrint('[OnboardingScreen] Paywall error: $e');
    }
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final strings = localeProvider.strings;
    return GestureDetector(
      onTap: () => _showLanguagePicker(context, localeProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_outlined,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              localeProvider.isPortuguese ? strings.portuguese : strings.english,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
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

class _TutorialItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _TutorialItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
