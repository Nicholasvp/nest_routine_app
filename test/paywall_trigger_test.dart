import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nestroutine/models/adapters/adapters.dart';
import 'package:nestroutine/services/paywall_trigger_service.dart';
import 'package:nestroutine/utils/storage_service.dart';

const _keys = [
  'paywall_install_date',
  'paywall_last_auto_shown',
  'paywall_auto_count_today',
  'paywall_today',
  'paywall_dismiss_count',
  'paywall_events_since_last',
];

DateTime _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days, hours: 1));

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('paywall_trigger');
    Hive.init(directory.path);
    Hive.registerAdapter(BabyAdapter());
    Hive.registerAdapter(BabyEventAdapter());
    Hive.registerAdapter(EventTypeAdapter());
    Hive.registerAdapter(FeedTypeAdapter());
    Hive.registerAdapter(FeedSideAdapter());
    Hive.registerAdapter(DiaperTextureAdapter());
    await StorageService.init();
  });

  setUp(() async {
    for (final key in _keys) {
      await StorageService.settingsBox.delete(key);
    }
    await PaywallTriggerService.init();
  });

  Future<void> setInstallDate(DateTime date) async {
    await StorageService.settingsBox.put(
      'paywall_install_date',
      date.toIso8601String(),
    );
  }

  bool canPresent({bool sleepTimerActive = false}) =>
      PaywallTriggerService.canPresent(
        trigger: 'app_resume',
        sleepTimerActive: sleepTimerActive,
      );

  group('PaywallTriggerService', () {
    test('bloqueia durante a carencia de instalacao', () async {
      expect(canPresent(), isFalse);
      expect(PaywallTriggerService.lastBlockReason, 'grace_period');
    });

    test('libera a partir do segundo dia de uso', () async {
      await setInstallDate(_daysAgo(5));
      expect(canPresent(), isTrue);
    });

    test('respeita o cooldown apos uma apresentacao', () async {
      await setInstallDate(_daysAgo(5));
      expect(canPresent(), isTrue);

      await PaywallTriggerService.recordShown();

      expect(canPresent(), isFalse);
      expect(PaywallTriggerService.lastBlockReason, 'cooldown');
    });

    test('limita a duas apresentacoes automaticas por dia', () async {
      await setInstallDate(_daysAgo(5));

      await PaywallTriggerService.recordShown();
      await PaywallTriggerService.recordShown();

      // Forca o cooldown ja ter passado para isolar a regra de limite diario.
      await StorageService.settingsBox.put(
        'paywall_last_auto_shown',
        _daysAgo(2).toIso8601String(),
      );

      expect(canPresent(), isFalse);
      expect(PaywallTriggerService.lastBlockReason, 'daily_limit_reached');
    });

    test('dispensas nao aumentam o intervalo de apresentacao', () async {
      await setInstallDate(_daysAgo(30));

      expect(PaywallTriggerService.currentInterval.inHours, 24);

      await PaywallTriggerService.recordDismiss();
      expect(PaywallTriggerService.currentInterval.inHours, 24);

      await PaywallTriggerService.recordDismiss();
      expect(PaywallTriggerService.currentInterval.inHours, 24);
    });

    test('dispensas repetidas nao desligam o paywall automatico', () async {
      await setInstallDate(_daysAgo(30));

      await PaywallTriggerService.recordDismiss();
      await PaywallTriggerService.recordDismiss();
      await PaywallTriggerService.recordDismiss();

      expect(canPresent(), isTrue);
    });

    test('compra ou restauracao zera o contador de dispensas', () async {
      await PaywallTriggerService.recordDismiss();
      expect(PaywallTriggerService.dismissCount, 1);

      await PaywallTriggerService.recordDismiss(reset: true);
      expect(PaywallTriggerService.dismissCount, 0);
    });

    test('nunca interrompe um timer de sono ativo', () async {
      await setInstallDate(_daysAgo(5));

      expect(canPresent(sleepTimerActive: true), isFalse);
      expect(PaywallTriggerService.lastBlockReason, 'sleep_timer_active');
    });

    test('conta eventos ate atingir o marco do paywall', () async {
      expect(PaywallTriggerService.eventsSinceLastPaywall, 0);

      for (var i = 0; i < PaywallTriggerService.eventsBetweenPaywalls; i++) {
        await PaywallTriggerService.recordEventLogged();
      }

      expect(
        PaywallTriggerService.eventsSinceLastPaywall,
        PaywallTriggerService.eventsBetweenPaywalls,
      );
    });

    test('uma apresentacao consome o marco de eventos', () async {
      for (var i = 0; i < PaywallTriggerService.eventsBetweenPaywalls; i++) {
        await PaywallTriggerService.recordEventLogged();
      }
      expect(
        PaywallTriggerService.eventsSinceLastPaywall,
        PaywallTriggerService.eventsBetweenPaywalls,
      );

      await PaywallTriggerService.recordShown();

      expect(PaywallTriggerService.eventsSinceLastPaywall, 0);
    });

    test('resetEventCounter zera o marco explicitamente', () async {
      await PaywallTriggerService.recordEventLogged();
      await PaywallTriggerService.recordEventLogged();
      expect(PaywallTriggerService.eventsSinceLastPaywall, 2);

      await PaywallTriggerService.resetEventCounter();
      expect(PaywallTriggerService.eventsSinceLastPaywall, 0);
    });

    test('cooldown expirado volta a liberar', () async {
      await setInstallDate(_daysAgo(30));
      await PaywallTriggerService.recordShown();
      expect(canPresent(), isFalse);

      await StorageService.settingsBox.put(
        'paywall_last_auto_shown',
        _daysAgo(2).toIso8601String(),
      );
      await StorageService.settingsBox.put('paywall_auto_count_today', 0);
      await StorageService.settingsBox.put('paywall_today', '');

      expect(canPresent(), isTrue);
    });
  });
}
