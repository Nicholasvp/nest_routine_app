import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/subscription_provider.dart';
import 'analytics_service.dart';
import 'meta_ads_service.dart';
import 'paywall_trigger_service.dart';
import 'purchase_service.dart';

/// De onde o paywall foi aberto. Vai para o Supabase em
/// `properties->>'trigger'` e permite comparar conversao por ponto.
class PaywallTriggerPoint {
  PaywallTriggerPoint._();

  static const onboarding = 'onboarding';
  static const appColdStart = 'app_cold_start';
  static const appResume = 'app_resume';
  static const homeBanner = 'home_banner';
  static const homeRoutineGate = 'home_routine_gate';
  static const insightsGate = 'insights_gate';
  static const insightsTabOpen = 'insights_tab_open';
  static const eventLogged = 'event_logged';
  static const notificationSettingsGate = 'notification_settings_gate';
  static const profileUpgrade = 'profile_upgrade';
}

/// Resultado normalizado da apresentacao, para o caller decidir o que fazer.
class PaywallOutcome {
  PaywallOutcome._();

  static const shown = 'shown';
  static const purchased = 'purchased';
  static const dismissed = 'dismissed';
  static const error = 'error';
  static const throttled = 'throttled';
  static const alreadyPro = 'already_pro';
}

/// Ponto unico de apresentacao do paywall.
///
/// Todas as telas devem passar por aqui. E o unico lugar que instrumenta o
/// funil completo (impressao, duracao, desfecho), aplica throttle e mantem o
/// locale do RevenueCat sincronizado.
class PaywallService {
  PaywallService._();

  static bool _isPresenting = false;

  static bool get isPresenting => _isPresenting;

  /// Apresenta o paywall e registra o funil no Supabase.
  ///
  /// [automatic] = true para gatilhos do proprio app (ex.: retomada do
  /// segundo plano). Nesses casos o throttle de [PaywallTriggerService] e
  /// aplicado. Gatilhos manuais (tap do usuario) ignoram o throttle.
  static Future<String> present(
    BuildContext context, {
    required String trigger,
    bool automatic = false,
    bool sleepTimerActive = false,
  }) async {
    // Leituras de provider ficam antes de qualquer await para nao guardar
    // BuildContext atraves de gaps assincronos.
    final subscription = context.read<SubscriptionProvider>();
    final analytics = AnalyticsService(
      context.read<AuthProvider>().authService,
    );
    final isPortuguese = context.read<LocaleProvider>().isPortuguese;

    if (subscription.isPro) {
      debugPrint('[PaywallService] Ja e Pro, ignorando trigger=$trigger');
      return PaywallOutcome.alreadyPro;
    }

    if (_isPresenting) {
      debugPrint('[PaywallService] Ja aberto, ignorando trigger=$trigger');
      return PaywallOutcome.throttled;
    }

    if (automatic &&
        !PaywallTriggerService.canPresent(
          trigger: trigger,
          sleepTimerActive: sleepTimerActive,
        )) {
      debugPrint(
        '[PaywallService] Bloqueado trigger=$trigger motivo=${PaywallTriggerService.lastBlockReason} '
        '(dispensas=${PaywallTriggerService.dismissCount}, eventosDesdeUltimo=${PaywallTriggerService.eventsSinceLastPaywall})',
      );
      unawaited(
        analytics.log(
          AnalyticsService.paywallThrottled,
          AnalyticsService.paywall,
          properties: {
            'trigger': trigger,
            'reason': PaywallTriggerService.lastBlockReason,
          },
        ),
      );
      return PaywallOutcome.throttled;
    }

    final dismissCount = PaywallTriggerService.dismissCount;
    final properties = {
      'trigger': trigger,
      'automatic': automatic,
      'dismiss_count': dismissCount,
    };

    await analytics.log(
      AnalyticsService.paywallShown,
      AnalyticsService.paywall,
      properties: properties,
    );

    PaywallTriggerService.recordShown();
    await _logCheckoutStarted(subscription);

    _isPresenting = true;
    final stopwatch = Stopwatch()..start();

    try {
      await PurchaseService.setPreferredLocale(isPortuguese);

      final result = await RevenueCatUI.presentPaywallIfNeeded(
        PurchaseService.proEntitlementId,
        displayCloseButton: true,
      );

      stopwatch.stop();
      final elapsed = stopwatch.elapsed;
      debugPrint(
        '[PaywallService] trigger=$trigger resultado=$result em ${elapsed.inMilliseconds}ms',
      );

      final outcome = await _handleResult(
        analytics: analytics,
        subscription: subscription,
        result: result,
        elapsed: elapsed,
        properties: properties,
      );
      return outcome;
    } catch (e) {
      stopwatch.stop();
      debugPrint('[PaywallService] Erro ao apresentar paywall: $e');
      await analytics.logDuration(
        AnalyticsService.paywallError,
        AnalyticsService.paywall,
        duration: stopwatch.elapsed,
        properties: {...properties, 'native_result': 'exception'},
      );
      return PaywallOutcome.error;
    } finally {
      _isPresenting = false;
    }
  }

  static Future<String> _handleResult({
    required AnalyticsService analytics,
    required SubscriptionProvider subscription,
    required PaywallResult result,
    required Duration elapsed,
    required Map<String, dynamic> properties,
  }) async {
    switch (result) {
      case PaywallResult.purchased:
        await analytics.logDuration(
          AnalyticsService.paywallPurchased,
          AnalyticsService.paywall,
          duration: elapsed,
          properties: properties,
        );
        await _logPurchase(subscription);
        PaywallTriggerService.recordDismiss(reset: true);
        await subscription.refresh();
        return PaywallOutcome.purchased;

      case PaywallResult.restored:
        await analytics.logDuration(
          AnalyticsService.paywallRestored,
          AnalyticsService.paywall,
          duration: elapsed,
          properties: properties,
        );
        await _logPurchase(subscription);
        PaywallTriggerService.recordDismiss(reset: true);
        await subscription.refresh();
        return PaywallOutcome.purchased;

      case PaywallResult.cancelled:
        await analytics.logDuration(
          AnalyticsService.paywallDismissed,
          AnalyticsService.paywall,
          duration: elapsed,
          properties: {
            ...properties,
            'dismiss_count': (properties['dismiss_count'] as int? ?? 0) + 1,
          },
        );
        PaywallTriggerService.recordDismiss();
        return PaywallOutcome.dismissed;

      case PaywallResult.notPresented:
      // Ja virou Pro entre o check e a apresentacao, ou offering ausente.
      case PaywallResult.error:
        await analytics.logDuration(
          AnalyticsService.paywallError,
          AnalyticsService.paywall,
          duration: elapsed,
          properties: {...properties, 'native_result': result.name},
        );
        return PaywallOutcome.error;
    }
  }

  /// Melhor pacote para mensurar checkout no Meta: anual quando existir.
  static Package? _featuredPackage(SubscriptionProvider subscription) {
    final packages =
        subscription.offerings?.current?.availablePackages ?? const [];
    if (packages.isEmpty) return null;
    return packages.firstWhere(
      (p) => p.identifier.contains('yearly'),
      orElse: () => packages.first,
    );
  }

  static Future<void> _logCheckoutStarted(
    SubscriptionProvider subscription,
  ) async {
    final pkg = _featuredPackage(subscription);
    if (pkg == null) return;
    await MetaAdsService.instance.logInitiatedCheckout(
      amount: pkg.storeProduct.price,
      currency: pkg.storeProduct.currencyCode,
      contentId: pkg.storeProduct.identifier,
    );
  }

  static Future<void> _logPurchase(SubscriptionProvider subscription) async {
    final pkg = _featuredPackage(subscription);
    if (pkg == null) return;
    await MetaAdsService.instance.logPurchase(
      amount: pkg.storeProduct.price,
      currency: pkg.storeProduct.currencyCode,
      contentId: pkg.storeProduct.identifier,
      orderId: pkg.identifier,
    );
  }
}
