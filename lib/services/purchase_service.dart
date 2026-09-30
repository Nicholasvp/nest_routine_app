import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  PurchaseService._();

  static const proEntitlementId = 'Nest Routine Pro';

  static Future<void> initialize({
    required String apiKey,
    bool isPortuguese = false,
  }) async {
    await Purchases.setLogLevel(LogLevel.debug);
    debugPrint(
        '[PurchaseService] Initializing with key: ${apiKey.substring(0, 8)}...');

    final configuration = PurchasesConfiguration(apiKey);

    if (isPortuguese) {
      configuration.preferredUILocaleOverride = 'pt-BR';
    }

    await Purchases.configure(configuration);
    debugPrint('[PurchaseService] Configured successfully');

    await _logOfferingsInfo();
  }

  static Future<void> _logOfferingsInfo() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        debugPrint('[PurchaseService] ⚠️ No current offering found');
        return;
      }
      debugPrint('[PurchaseService] Current offering: ${current.identifier}');
      for (final pkg in current.availablePackages) {
        debugPrint('[PurchaseService]   Package: ${pkg.identifier} | ${pkg.storeProduct.priceString}');
      }
    } catch (e) {
      debugPrint('[PurchaseService] ⚠️ Failed to fetch offerings: $e');
    }
  }

  static Future<bool> checkProStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      debugPrint('[PurchaseService] Customer ID: ${info.originalAppUserId}');
      debugPrint('[PurchaseService] Active entitlements: ${info.entitlements.active.keys.toList()}');
      debugPrint('[PurchaseService] Looking for entitlement: "$proEntitlementId"');
      final isPro = info.entitlements.active[proEntitlementId] != null;
      debugPrint('[PurchaseService] isPro = $isPro');
      return isPro;
    } catch (e) {
      debugPrint('[PurchaseService] ⚠️ Failed to check pro status: $e');
      return false;
    }
  }

  static Future<void> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      debugPrint('[PurchaseService] Restored. Active: ${info.entitlements.active.keys.toList()}');
    } catch (e) {
      debugPrint('[PurchaseService] ⚠️ Restore failed: $e');
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
