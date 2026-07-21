import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchase_service.dart';

enum PurchaseState { initial, loading, active, inactive, error }

class SubscriptionProvider extends ChangeNotifier {
  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  PurchaseState _state = PurchaseState.initial;
  String? _errorMessage;
  bool _initialized = false;

  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  PurchaseState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;

  bool get isPro {
    if (_customerInfo == null) return false;
    return PurchaseService.isProEntitlementActive(_customerInfo!);
  }

  EntitlementInfo? get proEntitlement {
    if (_customerInfo == null) return null;
    return PurchaseService.getProEntitlement(_customerInfo!);
  }

  String? get proExpirationDate {
    final entitlement = proEntitlement;
    if (entitlement == null) return null;
    return entitlement.expirationDate;
  }

  bool get isPurchaseLoading => _state == PurchaseState.loading;

  Future<void> initialize() async {
    _state = PurchaseState.loading;
    notifyListeners();

    try {
      _customerInfo = await PurchaseService.getCustomerInfo();
      _offerings = await PurchaseService.getOfferings();
      _initialized = true;
      _state = isPro ? PurchaseState.active : PurchaseState.inactive;
      _errorMessage = null;
    } catch (e) {
      _state = PurchaseState.inactive;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<PurchaseResult> purchase(Package package) async {
    _state = PurchaseState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await PurchaseService.purchasePackage(package);
      _customerInfo = info;
      _state = isPro ? PurchaseState.active : PurchaseState.inactive;
      notifyListeners();
      return PurchaseResult.success(info);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      final userCancelled = errorCode == PurchasesErrorCode.purchaseCancelledError;
      if (!userCancelled) {
        _errorMessage = e.message;
        _state = PurchaseState.error;
        notifyListeners();
      } else {
        _state = isPro ? PurchaseState.active : PurchaseState.inactive;
        notifyListeners();
      }
      return PurchaseResult.failure(e.message ?? 'Purchase failed', userCancelled: userCancelled);
    } catch (e) {
      _errorMessage = e.toString();
      _state = PurchaseState.error;
      notifyListeners();
      return PurchaseResult.failure(e.toString());
    }
  }

  Future<RestoreResult> restorePurchases() async {
    _state = PurchaseState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await PurchaseService.restorePurchases();
      _customerInfo = info;
      _state = isPro ? PurchaseState.active : PurchaseState.inactive;
      notifyListeners();
      return RestoreResult.success(info, isPro: isPro);
    } catch (e) {
      _errorMessage = e.toString();
      _state = PurchaseState.error;
      notifyListeners();
      return RestoreResult.failure(e.toString());
    }
  }

  void updateCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    _state = isPro ? PurchaseState.active : PurchaseState.inactive;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _state = isPro ? PurchaseState.active : PurchaseState.inactive;
    notifyListeners();
  }
}

class PurchaseResult {
  final CustomerInfo? customerInfo;
  final String? errorMessage;
  final bool userCancelled;
  final bool isSuccess;

  PurchaseResult._({
    this.customerInfo,
    this.errorMessage,
    this.userCancelled = false,
    required this.isSuccess,
  });

  factory PurchaseResult.success(CustomerInfo info) =>
      PurchaseResult._(customerInfo: info, isSuccess: true);

  factory PurchaseResult.failure(String message, {bool userCancelled = false}) =>
      PurchaseResult._(
        errorMessage: message,
        userCancelled: userCancelled,
        isSuccess: false,
      );
}

class RestoreResult {
  final CustomerInfo? customerInfo;
  final String? errorMessage;
  final bool isPro;
  final bool isSuccess;

  RestoreResult._({
    this.customerInfo,
    this.errorMessage,
    this.isPro = false,
    required this.isSuccess,
  });

  factory RestoreResult.success(CustomerInfo info, {required bool isPro}) =>
      RestoreResult._(customerInfo: info, isPro: isPro, isSuccess: true);

  factory RestoreResult.failure(String message) =>
      RestoreResult._(errorMessage: message, isSuccess: false);
}
