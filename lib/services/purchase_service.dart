import 'dart:developer' as developer;
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  PurchaseService._();

  static const _tag = 'PurchaseService';

  static const _proEntitlementId = 'Nest Routine Pro';

  static Future<void> initialize(String apiKey) async {
    try {
      await Purchases.setup(apiKey);
      developer.log('RevenueCat initialized', name: _tag);
    } catch (e) {
      developer.log('Failed to initialize RevenueCat: $e', name: _tag);
      rethrow;
    }
  }

  static Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      developer.log('Failed to fetch offerings: $e', name: _tag);
      return null;
    }
  }

  static Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      return info;
    } catch (e) {
      developer.log('Purchase failed: $e', name: _tag);
      rethrow;
    }
  }

  static Future<CustomerInfo> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info;
    } catch (e) {
      developer.log('Restore failed: $e', name: _tag);
      rethrow;
    }
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      developer.log('Failed to get customer info: $e', name: _tag);
      rethrow;
    }
  }

  static bool isProEntitlementActive(CustomerInfo info) {
    return info.entitlements.active[_proEntitlementId] != null;
  }

  static EntitlementInfo? getProEntitlement(CustomerInfo info) {
    return info.entitlements.all[_proEntitlementId];
  }

  static Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      developer.log('Failed to log in user: $e', name: _tag);
    }
  }

  static Future<void> clearUserId() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      developer.log('Failed to log out user: $e', name: _tag);
    }
  }

  static Future<void> setAttributes(Map<String, String> attributes) async {
    try {
      await Purchases.setAttributes(attributes);
    } catch (e) {
      developer.log('Failed to set attributes: $e', name: _tag);
    }
  }
}
