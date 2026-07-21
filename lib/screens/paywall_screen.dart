import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../utils/strings.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _useNativePaywall = true;

  @override
  void initState() {
    super.initState();
    _checkNativePaywall();
  }

  Future<void> _checkNativePaywall() async {
    final sub = context.read<SubscriptionProvider>();
    final offering = sub.offerings?.current;
    if (offering == null || offering.availablePackages.isEmpty) {
      if (mounted) setState(() => _useNativePaywall = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useNativePaywall) {
      return _buildNativePaywall();
    }
    return _buildCustomPaywall();
  }

  Widget _buildNativePaywall() {
    return PaywallView(
      onPurchaseCompleted: (customerInfo, storeTransaction) {
        context.read<SubscriptionProvider>().updateCustomerInfo(customerInfo);
      },
      onRestoreCompleted: (customerInfo) {
        context.read<SubscriptionProvider>().updateCustomerInfo(customerInfo);
      },
      onDismiss: () => Navigator.pop(context),
    );
  }

  Widget _buildCustomPaywall() {
    final strings = context.watch<LocaleProvider>().strings;
    final sub = context.watch<SubscriptionProvider>();
    final offering = sub.offerings?.current;

    if (offering == null) {
      return _buildNoOfferings(strings);
    }

    final packages = offering.availablePackages;
    if (packages.isEmpty) {
      return _buildNoOfferings(strings);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildHeader(context, strings),
                    const SizedBox(height: 32),
                    ...packages.map((pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PackageCard(
                        package: pkg,
                        strings: strings,
                        isPopular: pkg.identifier.contains('yearly'),
                        onPurchase: () => _purchase(sub, pkg),
                        isLoading: sub.isPurchaseLoading,
                      ),
                    )),
                    const SizedBox(height: 16),
                    _buildRestoreButton(context, sub, strings),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Strings strings) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.sleepPurple.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star_rounded,
            color: AppColors.wakeYellow,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          strings.paywallTitle,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.paywallSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _buildFeatureRow(Icons.auto_graph_rounded, 'Advanced insights & analytics'),
        _buildFeatureRow(Icons.history_rounded, 'Unlimited history'),
        _buildFeatureRow(Icons.notifications_active_rounded, 'Smart predictions'),
        _buildFeatureRow(Icons.baby_changing_station_rounded, 'Multiple babies'),
        _buildFeatureRow(Icons.cloud_sync_rounded, 'Cloud backup'),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(BuildContext context, SubscriptionProvider sub, Strings strings) {
    return TextButton(
      onPressed: sub.isPurchaseLoading
          ? null
          : () => _restore(sub),
      child: Text(
        strings.restorePurchases,
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildNoOfferings(Strings strings) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.textTertiary, size: 48),
                const SizedBox(height: 16),
                Text(
                  strings.unableToLoadOfferings,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.read<SubscriptionProvider>().refresh(),
                  child: Text(strings.retry),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _purchase(SubscriptionProvider sub, Package package) async {
    final result = await sub.purchase(package);
    if (result.isSuccess && mounted) {
      Navigator.pop(context, true);
    } else if (!result.userCancelled && result.errorMessage != null && mounted) {
      _showError(result.errorMessage!);
    }
  }

  Future<void> _restore(SubscriptionProvider sub) async {
    final strings = context.read<LocaleProvider>().strings;
    final result = await sub.restorePurchases();
    if (!mounted) return;
    if (result.isSuccess && result.isPro) {
      Navigator.pop(context, true);
    } else if (result.isSuccess && !result.isPro) {
      _showError(strings.noPurchasesFound);
    } else if (result.errorMessage != null) {
      _showError(result.errorMessage!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Package package;
  final Strings strings;
  final bool isPopular;
  final VoidCallback onPurchase;
  final bool isLoading;

  const _PackageCard({
    required this.package,
    required this.strings,
    required this.isPopular,
    required this.onPurchase,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? AppColors.sleepPurple : AppColors.cardBorder,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.sleepPurple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Text(
                  strings.bestValue,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _label(package.identifier),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          package.storeProduct.priceString,
                          style: TextStyle(
                            color: isPopular
                                ? AppColors.sleepPurple
                                : AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (package.storeProduct.introductoryPrice != null)
                          Text(
                            'then ${package.storeProduct.introductoryPrice!.priceString}',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (package.storeProduct.description.isNotEmpty)
                  Text(
                    package.storeProduct.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading ? null : onPurchase,
                    style: FilledButton.styleFrom(
                      backgroundColor: isPopular
                          ? AppColors.sleepPurple
                          : AppColors.mediumPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            strings.subscribe,
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
        ],
      ),
    );
  }

  String _label(String identifier) {
    if (identifier.contains('monthly')) return strings.monthly;
    if (identifier.contains('yearly')) return strings.yearly;
    if (identifier.contains('lifetime')) return strings.lifetime;
    return identifier;
  }
}
