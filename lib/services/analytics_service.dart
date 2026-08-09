import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
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

  // Eventos de feature
  static const viewInsights = 'view_insights';
  static const viewHistory = 'view_history';
  static const useTimer = 'use_timer';

  // Eventos de erro
  static const syncFailed = 'sync_failed';

  Future<void> log(
    String eventName,
    String category, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      final userId = _authService.userId;
      await _client.from('analytics_events').insert({
        if (userId != null) 'user_id': userId,
        'event_name': eventName,
        'event_category': category,
        if (properties != null) 'properties': properties,
        'platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      debugPrint('[Analytics] Failed to log $eventName: $e');
    }
  }
}
