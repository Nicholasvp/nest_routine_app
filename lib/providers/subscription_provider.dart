import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchase_service.dart';

class PurchaseResult {
  final bool isSuccess;
  final bool userCancelled;
  final bool isPro;
  final String? errorMessage;

  const PurchaseResult({
    required this.isSuccess,
    this.userCancelled = false,
    this.isPro = false,
    this.errorMessage,
  });
}

class SubscriptionProvider extends ChangeNotifier {
  bool _initialized = false;
  bool _isPro = false;
  bool _isPurchaseLoading = false;
  Offerings? _offerings;

  bool get initialized => _initialized;
  bool get isPro => _isPro;
  bool get isPurchaseLoading => _isPurchaseLoading;
  Offerings? get offerings => _offerings;

  Future<void> initialize() async {
    debugPrint('[SubscriptionProvider] Initializing...');
    try {
      _offerings = await Purchases.getOfferings();
      final current = _offerings?.current;
      debugPrint('[SubscriptionProvider] Offerings loaded: current=${current?.identifier}, packages=${current?.availablePackages.length ?? 0}');
    } catch (e) {
      debugPrint('[SubscriptionProvider] ⚠️ Failed to load offerings: $e');
    }
    _isPro = await PurchaseService.checkProStatus();
    _initialized = true;
    debugPrint('[SubscriptionProvider] Initialized: isPro=$_isPro');
    notifyListeners();
  }

  Future<void> refresh() async {
    await initialize();
  }

  void updateCustomerInfo(CustomerInfo info) {
    _isPro = info.entitlements.active[PurchaseService.proEntitlementId] != null;
    debugPrint('[SubscriptionProvider] Updated via customerInfo: isPro=$_isPro');
    notifyListeners();
  }

  void updateFromCustomerInfo(CustomerInfo info) {
    updateCustomerInfo(info);
  }

  Future<PurchaseResult> purchase(Package package) async {
    debugPrint('[SubscriptionProvider] Starting purchase for: ${package.identifier}');
    _isPurchaseLoading = true;
    notifyListeners();

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final activeEntitlements = result.customerInfo.entitlements.active.keys.toList();
      debugPrint('[SubscriptionProvider] Purchase completed. Active entitlements: $activeEntitlements');
      _isPro = result.customerInfo.entitlements.active[PurchaseService.proEntitlementId] != null;
      debugPrint('[SubscriptionProvider] isPro after purchase: $_isPro');
      _isPurchaseLoading = false;
      notifyListeners();
      return const PurchaseResult(isSuccess: true);
    } on PlatformException catch (e) {
      debugPrint('[SubscriptionProvider] ⚠️ Purchase PlatformException: code=${e.code}, message=${e.message}');
      _isPurchaseLoading = false;
      notifyListeners();

      final msg = e.message?.toLowerCase() ?? '';
      if (msg.contains('cancel')) {
        debugPrint('[SubscriptionProvider] Purchase cancelled by user');
        return const PurchaseResult(isSuccess: false, userCancelled: true);
      }
      return PurchaseResult(
        isSuccess: false,
        errorMessage: e.message ?? 'Purchase failed',
      );
    } catch (e) {
      debugPrint('[SubscriptionProvider] ⚠️ Purchase unexpected error: $e');
      _isPurchaseLoading = false;
      notifyListeners();
      return PurchaseResult(
        isSuccess: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<PurchaseResult> restorePurchases() async {
    debugPrint('[SubscriptionProvider] Starting restore...');
    _isPurchaseLoading = true;
    notifyListeners();

    try {
      final result = await Purchases.restorePurchases();
      final activeEntitlements = result.entitlements.active.keys.toList();
      debugPrint('[SubscriptionProvider] Restore completed. Active entitlements: $activeEntitlements');
      _isPro = result.entitlements.active[PurchaseService.proEntitlementId] != null;
      debugPrint('[SubscriptionProvider] isPro after restore: $_isPro');
      _isPurchaseLoading = false;
      notifyListeners();
      return PurchaseResult(isSuccess: true, isPro: _isPro);
    } catch (e) {
      debugPrint('[SubscriptionProvider] ⚠️ Restore error: $e');
      _isPurchaseLoading = false;
      notifyListeners();
      return PurchaseResult(
        isSuccess: false,
        errorMessage: 'Restore failed: $e',
      );
    }
  }
}
