import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Regras de frequencia do paywall automatico.
///
/// Sem isso o paywall vira fonte de churn e nota baixa. Os gatilhos manuais
/// (tap do usuario em "Assinar") nunca passam por aqui e sempre abrem.
class PaywallTriggerService {
  PaywallTriggerService._();

  // Getter em vez de campo `late`: evita LateInitializationError se algum
  // teste ou caminho frio chamar o servico sem passar pelo init().
  static Box get _box => Hive.box('settings');

  static bool get _ready => Hive.isBoxOpen('settings');

  /// Intervalo minimo entre apresentacoes automaticas.
  static const Duration baseInterval = Duration(hours: 24);

  /// Maximo de apresentacoes automaticas por dia.
  static const int maxPerDay = 2;

  /// Dias desde a instalacao antes da primeira apresentacao automatica.
  /// 1 = so a partir do segundo dia de uso.
  static const int graceDays = 1;

  /// A partir desse numero de dispensas o paywall automatico e desligado;
  /// so resta o caminho manual.
  static const int maxDismissCount = 3;

  /// Eventos registrados desde a ultima tentativa antes de considerar o
  /// gatilho de "criacao de evento". Evita abrir o paywall no primeiro
  /// registro do usuario e limita a quantidade de tentativas por dia.
  static const int eventsBetweenPaywalls = 3;

  static const _keyInstallDate = 'paywall_install_date';
  static const _keyLastAutoShown = 'paywall_last_auto_shown';
  static const _keyAutoCountToday = 'paywall_auto_count_today';
  static const _keyToday = 'paywall_today';
  static const _keyDismissCount = 'paywall_dismiss_count';
  static const _keyEventsSinceLastPaywall = 'paywall_events_since_last';

  static String _lastBlockReason = '';

  /// Motivo do ultimo bloqueio, para o evento `paywall_throttled`.
  static String get lastBlockReason => _lastBlockReason;

  static Future<void> init() async {
    final box = Hive.isBoxOpen('settings')
        ? Hive.box('settings')
        : await Hive.openBox('settings');
    if (box.get(_keyInstallDate) == null) {
      await box.put(_keyInstallDate, DateTime.now().toIso8601String());
    }
  }

  static int get dismissCount {
    if (!_ready) return 0;
    return _box.get(_keyDismissCount, defaultValue: 0) as int;
  }

  static int get eventsSinceLastPaywall {
    if (!_ready) return 0;
    return _box.get(_keyEventsSinceLastPaywall, defaultValue: 0) as int;
  }

  static DateTime? get _installDate {
    if (!_ready) return null;
    final raw = _box.get(_keyInstallDate) as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static DateTime? get _lastAutoShown {
    if (!_ready) return null;
    final raw = _box.get(_keyLastAutoShown) as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Intervalo exigido cresce conforme o usuario dispensa o paywall.
  static Duration get currentInterval =>
      baseInterval * (dismissCount + 1).clamp(1, 4);

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static int get _autoCountToday {
    if (!_ready) return 0;
    final storedDay = _box.get(_keyToday) as String?;
    if (storedDay != _todayKey()) return 0;
    return _box.get(_keyAutoCountToday, defaultValue: 0) as int;
  }

  /// Decide se um gatilho automatico pode abrir o paywall agora.
  static bool canPresent({
    required String trigger,
    bool sleepTimerActive = false,
  }) {
    _lastBlockReason = '';

    if (sleepTimerActive) {
      _lastBlockReason = 'sleep_timer_active';
      return false;
    }

    if (!_ready) {
      _lastBlockReason = 'storage_not_ready';
      return false;
    }

    if (dismissCount >= maxDismissCount) {
      _lastBlockReason = 'too_many_dismissals';
      return false;
    }

    final install = _installDate;
    if (install == null) {
      _lastBlockReason = 'no_install_date';
      return false;
    }
    if (DateTime.now().difference(install).inDays < graceDays) {
      _lastBlockReason = 'grace_period';
      return false;
    }

    if (_autoCountToday >= maxPerDay) {
      _lastBlockReason = 'daily_limit_reached';
      return false;
    }

    final last = _lastAutoShown;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < currentInterval) {
        _lastBlockReason = 'cooldown';
        return false;
      }
    }

    return true;
  }

  /// Conta um evento registrado pelo usuario.
  static Future<void> recordEventLogged() async {
    if (!_ready) return;
    await _box.put(_keyEventsSinceLastPaywall, eventsSinceLastPaywall + 1);
  }

  /// Volta a um estado " usuario recorrente " instantaneamente.
  ///
  /// Necessario porque a carencia de instalacao e o contador de dispensas
  /// tornam o paywall automatico intestavel em tempo real: sem isso, quem
  /// fecha o paywall 3 vezes nunca mais ve outro automatico.
  /// [installDaysAgo] controla a idade simulada da instalacao
  /// ([graceDays] e medido a partir dela).
  static Future<void> debugReset({int installDaysAgo = 30}) async {
    if (!_ready) return;
    await Future.wait([
      _box.delete(_keyLastAutoShown),
      _box.delete(_keyAutoCountToday),
      _box.delete(_keyToday),
      _box.delete(_keyDismissCount),
      _box.delete(_keyEventsSinceLastPaywall),
      _box.put(
        _keyInstallDate,
        DateTime.now()
            .subtract(Duration(days: installDaysAgo))
            .toIso8601String(),
      ),
    ]);
    debugPrint(
        '[PaywallTriggerService] Estado resetado (instalacao ha ${installDaysAgo}d)');
  }

  /// Um resumo do estado atual, para log e telas de debug.
  static Map<String, dynamic> get debugState => {
        'install_date': _installDate?.toIso8601String(),
        'last_auto_shown': _lastAutoShown?.toIso8601String(),
        'auto_count_today': _autoCountToday,
        'dismiss_count': dismissCount,
        'events_since_last': eventsSinceLastPaywall,
        'required_interval_hours': currentInterval.inHours,
      };

  /// Zera o contador de eventos, para o marco ter que ser atingido de novo.
  static Future<void> resetEventCounter() async {
    if (!_ready) return;
    await _box.put(_keyEventsSinceLastPaywall, 0);
  }

  /// Marca que uma apresentacao automatica aconteceu.
  static Future<void> recordShown() async {
    if (!_ready) return;
    // Uma tentativa, mesmo barrada pelo throttle, consome o marco: sem isso o
    // usuario veria o paywall a cada evento assim que o cooldown vencesse.
    await resetEventCounter();
    final today = _todayKey();
    final previousDay = _box.get(_keyToday) as String?;
    final count = previousDay == today
        ? (_box.get(_keyAutoCountToday, defaultValue: 0) as int) + 1
        : 1;

    await Future.wait([
      _box.put(_keyLastAutoShown, DateTime.now().toIso8601String()),
      _box.put(_keyToday, today),
      _box.put(_keyAutoCountToday, count),
    ]);
  }

  /// Registra dispensa. Uma compra/restauracao zera o contador.
  static Future<void> recordDismiss({bool reset = false}) async {
    if (!_ready) return;
    await _box.put(
      _keyDismissCount,
      reset ? 0 : dismissCount + 1,
    );
  }
}
