import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  PurchaseService._();

  static const proEntitlementId = 'Nest Routine Pro';

  static Future<void> initialize({
    required String iosApiKey,
    bool isPortuguese = false,
  }) async {
    await Purchases.setLogLevel(LogLevel.debug);
    debugPrint('[PurchaseService] LogLevel set to debug');

    final configuration = PurchasesConfiguration(iosApiKey);
    debugPrint('[PurchaseService] Configuring for iOS');

    if (isPortuguese) {
      configuration.preferredUILocaleOverride = 'pt-BR';
    }

    await Purchases.configure(configuration);
    debugPrint('[PurchaseService] RevenueCat configured');
  }

  static Future<bool> checkProStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final isPro = info.entitlements.active[proEntitlementId] != null;
      debugPrint('[PurchaseService] Pro status: $isPro');
      return isPro;
    } catch (e) {
      debugPrint('[PurchaseService] Failed to check pro status: $e');
      return false;
    }
  }

  static Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      debugPrint('[PurchaseService] Purchases restored');
    } catch (e) {
      debugPrint('[PurchaseService] Restore failed: $e');
      rethrow;
    }
  }

  static Future<void> setPreferredLocale(bool isPortuguese) async {
    try {
      final locale = isPortuguese ? 'pt-BR' : null;
      await Purchases.overridePreferredUILocale(locale);
      debugPrint('[PurchaseService] Preferred locale set to $locale');
    } catch (e) {
      debugPrint('[PurchaseService] Failed to set preferred locale: $e');
    }
  }
}
