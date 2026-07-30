import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchase_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  bool _initialized = false;
  bool _isPro = false;

  bool get initialized => _initialized;
  bool get isPro => _isPro;

  Future<void> initialize() async {
    debugPrint('[SubscriptionProvider] Initializing...');
    _isPro = await PurchaseService.checkProStatus();
    _initialized = true;
    debugPrint('[SubscriptionProvider] Initialized: isPro=$_isPro');
    notifyListeners();
  }

  Future<void> refresh() async {
    await initialize();
  }

  void updateFromCustomerInfo(CustomerInfo info) {
    _isPro = info.entitlements.active[PurchaseService.proEntitlementId] != null;
    debugPrint('[SubscriptionProvider] Updated: isPro=$_isPro');
    notifyListeners();
  }
}
