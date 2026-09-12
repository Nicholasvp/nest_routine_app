import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class MetaAdsService {
  MetaAdsService._();

  static final MetaAdsService instance = MetaAdsService._();

  static const String appId = '1473780261310771';

  static const String _contentTypeSubscription = 'subscription';

  final FacebookAppEvents _fb = FacebookAppEvents();

  bool _initialized = false;

  bool get isSupported => !kIsWeb && Platform.isIOS;

  bool get _ready => _initialized && isSupported;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isSupported) {
      debugPrint('[MetaAds] Desativado: SDK configurado apenas para iOS');
      return;
    }

    try {
      if (kDebugMode) {
        await _fb.setDebugLoggingEnabled(true);
      }
      _askConsentThenActivate();
    } catch (e) {
      debugPrint('[MetaAds] Falha ao inicializar: $e');
    }
  }

  /// O log automatico (install/launch) fica desligado pelo Info.plist ate o
  /// usuario responder ao ATT. Ativar antes disso registra o evento sem
  /// consentimento e ele nao entra na mensuracao das campanhas.
  void _askConsentThenActivate() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var granted = false;
      try {
        await Future<void>.delayed(const Duration(milliseconds: 500));

        var status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          status = await AppTrackingTransparency.requestTrackingAuthorization();
        }

        granted = status == TrackingStatus.authorized;
        debugPrint('[MetaAds] ATT status: $status');
        await _applyTrackingConsent(granted);
      } catch (e) {
        debugPrint('[MetaAds] Falha ao solicitar ATT: $e');
      } finally {
        await _activate(granted);
      }
    });
  }

  Future<void> _applyTrackingConsent(bool granted) async {
    // ignore: deprecated_member_use
    await _fb.setAdvertiserTracking(enabled: granted, collectId: granted);
    await _fb.setAdvertiserIdCollectionEnabled(granted);
  }

  Future<void> _activate(bool granted) async {
    try {
      await _fb.setAutoLogAppEventsEnabled(true);
      await _fb.activateApp();
      debugPrint('[MetaAds] SDK ativado (app $appId, advertiserTracking=$granted)');
    } catch (e) {
      debugPrint('[MetaAds] Falha ao ativar: $e');
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!_ready) return;
    try {
      if (userId == null) {
        await _fb.clearUserID();
        return;
      }
      await _fb.setUserID(userId);
    } catch (e) {
      debugPrint('[MetaAds] Falha ao definir user id: $e');
    }
  }

  Future<void> logSignUp({String method = 'email'}) {
    return _run('completedRegistration', () => _fb.logCompletedRegistration(
          registrationMethod: method,
        ));
  }

  Future<void> logCompletedTutorial() {
    return _run('completedTutorial', () => _fb.logCompletedTutorial());
  }

  Future<void> logInitiatedCheckout({
    required double amount,
    required String currency,
    required String contentId,
  }) {
    return _run(
      'initiatedCheckout',
      () => _fb.logInitiatedCheckout(
        totalPrice: amount,
        currency: currency,
        contentId: contentId,
        contentType: _contentTypeSubscription,
        numItems: 1,
      ),
    );
  }

  Future<void> logPurchase({
    required double amount,
    required String currency,
    required String contentId,
    String? orderId,
    bool isSubscription = true,
  }) {
    return _run('purchase', () async {
      // Sem valor conhecido, registra apenas a conversao de assinatura para
      // nao poluir o ROAS com uma compra de valor zero.
      if (amount <= 0 || currency.isEmpty) {
        await _fb.logSubscribe(orderId: orderId ?? contentId);
        await _fb.flush();
        return;
      }

      await _fb.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {
          FacebookAppEvents.paramNameContentId: contentId,
          FacebookAppEvents.paramNameContentType: _contentTypeSubscription,
          if (orderId != null) FacebookAppEvents.paramNameOrderId: orderId,
        },
      );

      if (isSubscription) {
        // Sem preco: o valor ja foi enviado no logPurchase acima.
        await _fb.logSubscribe(
          currency: currency,
          orderId: orderId ?? contentId,
        );
      }

      await _fb.flush();
    });
  }

  Future<void> logAddBaby() {
    return _run('add_baby', () => _fb.logEvent(name: 'add_baby'));
  }

  Future<void> logViewInsights() {
    return _run('view_insights', () => _fb.logEvent(name: 'view_insights'));
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    if (!_ready) return;
    try {
      await action();
    } catch (e) {
      debugPrint('[MetaAds] Falha ao registrar $label: $e');
    }
  }
}
