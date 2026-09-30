import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class AnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService;

  AnalyticsService(this._authService);

  // Categorias
  static const usage = 'usage';
  static const engagement = 'engagement';
  static const feature = 'feature';
  static const error = 'error';
  static const paywall = 'paywall';
  static const onboarding = 'onboarding';

  // Eventos de uso
  static const addBaby = 'add_baby';
  static const removeBaby = 'remove_baby';
  static const addEvent = 'add_event';
  static const removeEvent = 'remove_event';
  static const startSleep = 'start_sleep';
  static const stopSleep = 'stop_sleep';
  static const startFeed = 'start_feed';
  static const stopFeed = 'stop_feed';
  static const addDiaper = 'add_diaper';

  // Eventos de engajamento
  static const login = 'login';
  static const signup = 'signup';
  static const screenView = 'screen_view';
  static const appOpen = 'app_open';
  static const appResumed = 'app_resumed';

  // Eventos de feature
  static const viewInsights = 'view_insights';
  static const viewHistory = 'view_history';
  static const useTimer = 'use_timer';

  // Eventos de erro
  static const syncFailed = 'sync_failed';

  // ── Paywall ──
  // 'trigger' identifica onde o paywall foi aberto
  // (onboarding, home_banner, insights_gate, notification_settings_gate,
  //  profile_upgrade, app_resume).
  static const paywallShown = 'paywall_shown';
  static const paywallDismissed = 'paywall_dismissed';
  static const paywallPurchased = 'paywall_purchased';
  static const paywallRestored = 'paywall_restored';
  static const paywallRestoreFailed = 'paywall_restore_failed';
  static const paywallPurchaseFailed = 'paywall_purchase_failed';
  static const paywallPurchaseCancelled = 'paywall_purchase_cancelled';
  static const paywallError = 'paywall_error';
  static const paywallThrottled = 'paywall_throttled';

  // ── Onboarding ──
  static const onboardingStarted = 'onboarding_started';
  static const onboardingPageView = 'onboarding_page_view';
  static const onboardingSkipped = 'onboarding_skipped';
  static const onboardingCompleted = 'onboarding_completed';

  /// Identificador unico do processo atual do app. Costura onboarding e
  /// paywall dentro do mesmo launch, inclusive para usuarios sem conta.
  static String? _sessionId;

  static final Random _random = Random.secure();

  static String get sessionId => _sessionId ??= _newSessionId();

  static String _newSessionId() {
    final seed = List<int>.generate(8, (_) => _random.nextInt(256));
    final suffix = seed.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${DateTime.now().millisecondsSinceEpoch}-$suffix';
  }

  static String? _cachedAppVersion;
  static bool _appVersionLoading = false;

  static Future<String?> _resolveAppVersion() async {
    if (_cachedAppVersion != null) return _cachedAppVersion;
    if (_appVersionLoading) return null;
    _appVersionLoading = true;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedAppVersion = info.version;
    } catch (_) {
      _cachedAppVersion = null;
    } finally {
      _appVersionLoading = false;
    }
    return _cachedAppVersion;
  }

  Future<void> log(
    String eventName,
    String category, {
    Map<String, dynamic>? properties,
    Duration? duration,
  }) async {
    await _insert(
      eventName: eventName,
      category: category,
      properties: properties,
      durationMs: duration?.inMilliseconds,
    );
  }

  /// Versao que aceita duracao ja medida em milissegundos.
  /// Usada quando o valor vem de fora (ex.: tempo por pagina do onboarding).
  Future<void> logDuration(
    String eventName,
    String category, {
    Map<String, dynamic>? properties,
    required Duration duration,
  }) async {
    await _insert(
      eventName: eventName,
      category: category,
      properties: properties,
      durationMs: duration.inMilliseconds,
    );
  }

  Future<void> _insert({
    required String eventName,
    required String category,
    Map<String, dynamic>? properties,
    int? durationMs,
  }) async {
    try {
      final userId = _authService.userId;
      final appVersion = await _resolveAppVersion();
      await _client.from('analytics_events').insert({
        if (userId != null) 'user_id': userId,
        'session_id': sessionId,
        'event_name': eventName,
        'event_category': category,
        if (properties != null && properties.isNotEmpty) 'properties': properties,
        'platform': defaultTargetPlatform.name,
        if (appVersion != null) 'app_version': appVersion,
        if (durationMs != null) 'duration_ms': durationMs,
      });
    } catch (e) {
      debugPrint('[Analytics] Failed to log $eventName: $e');
    }
  }
}
