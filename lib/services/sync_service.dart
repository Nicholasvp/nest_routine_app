import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/baby.dart';
import '../models/event.dart';
import '../utils/storage_service.dart';
import 'auth_service.dart';
import 'analytics_service.dart';

class SyncService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService;
  late final AnalyticsService _analyticsService;

  SyncService(this._authService) {
    _analyticsService = AnalyticsService(_authService);
  }

  String? get _userId => _authService.userId;

  /// The signed in user's id, or null when anonymous.
  String? get userId => _authService.userId;

  bool get isLoggedIn => _authService.isLoggedIn;

  // ── Babies ──

  /// Pushes every locally created baby and event to the cloud, keeping their
  /// original UUIDs so nothing is duplicated.
  ///
  /// Runs once per user — guarded by [StorageService.isLocalDataMigrated] — so
  /// data created while offline survives the first sign in.
  Future<void> migrateLocalDataToCloud(String userId) async {
    if (!isLoggedIn) return;
    if (StorageService.isLocalDataMigrated(userId)) return;

    final localBabies = StorageService.loadBabies();
    if (localBabies.isEmpty) {
      await StorageService.setLocalDataMigrated(userId);
      return;
    }

    try {
      await _client
          .from('babies')
          .upsert(localBabies.map(_babyToJson).toList());

      for (final baby in localBabies) {
        final events = StorageService.loadEvents(baby.id);
        if (events.isEmpty) continue;
        for (final chunk in _chunks(events, 500)) {
          await _client.from('events').upsert(chunk.map(_eventToJson).toList());
        }
      }

      await StorageService.setLocalDataMigrated(userId);
      debugPrint(
        '[SyncService] Migrated ${localBabies.length} local babies to cloud',
      );
    } catch (e) {
      debugPrint('[SyncService] Local data migration failed: $e');
      _analyticsService.log(
        AnalyticsService.syncFailed,
        AnalyticsService.error,
        properties: {'operation': 'migrate_local_data', 'error': e.toString()},
      );
    }
  }

  Iterable<List<T>> _chunks<T>(List<T> source, int size) sync* {
    for (var i = 0; i < source.length; i += size) {
      yield source.sublist(
        i,
        i + size > source.length ? source.length : i + size,
      );
    }
  }

  Map<String, dynamic> _babyToJson(Baby baby) => {
    'id': baby.id,
    'user_id': _userId,
    'name': baby.name,
    'photo_path': baby.photoPath,
    'date_of_birth': baby.dateOfBirth.toUtc().toIso8601String(),
    'created_at': baby.createdAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _eventToJson(BabyEvent event) => {
    'id': event.id,
    'baby_id': event.babyId,
    'user_id': _userId,
    'type': event.type.name,
    'start_time': event.startTime.toUtc().toIso8601String(),
    'end_time': event.endTime?.toUtc().toIso8601String(),
    'notes': event.notes,
    'feed_type': event.feedType?.name,
    'feed_side': event.feedSide?.name,
    'duration_minutes': event.durationMinutes,
    'volume_ml': event.volumeMl,
    'has_pee': event.hasPee,
    'has_poop': event.hasPoop,
    'diaper_texture': event.diaperTexture?.name,
  };

  Future<void> syncBabyToSupabase(Baby baby) async {
    if (!isLoggedIn) return;
    try {
      await _client.from('babies').upsert(_babyToJson(baby));
    } catch (e) {
      debugPrint('[SyncService] Failed to sync baby: $e');
      _analyticsService.log(
        AnalyticsService.syncFailed,
        AnalyticsService.error,
        properties: {'operation': 'sync_baby', 'error': e.toString()},
      );
    }
  }

  Future<void> deleteBabyFromSupabase(String babyId) async {
    if (!isLoggedIn) return;
    try {
      await _client.from('babies').delete().eq('id', babyId);
    } catch (e) {
      debugPrint('[SyncService] Failed to delete baby: $e');
      _analyticsService.log(
        AnalyticsService.syncFailed,
        AnalyticsService.error,
        properties: {'operation': 'delete_baby', 'error': e.toString()},
      );
    }
  }

  Future<List<Baby>> loadBabiesFromSupabase() async {
    if (!isLoggedIn) return [];
    try {
      final data = await _client
          .from('babies')
          .select()
          .eq('user_id', _userId!)
          .order('created_at');
      return (data as List).map((json) => Baby.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[SyncService] Failed to load babies: $e');
      _analyticsService.log(
        AnalyticsService.syncFailed,
        AnalyticsService.error,
        properties: {'operation': 'load_babies', 'error': e.toString()},
      );
      return [];
    }
  }

  // ── Events ──

  Future<void> syncEventToSupabase(BabyEvent event) async {
    if (!isLoggedIn) return;
    try {
      await _client.from('events').upsert(_eventToJson(event));
    } catch (e) {
      debugPrint('[SyncService] Failed to sync event: $e');
      _analyticsService.log(
        AnalyticsService.syncFailed,
        AnalyticsService.error,
        properties: {'operation': 'sync_event', 'error': e.toString()},
      );
    }
  }

  Future<void> deleteEventFromSupabase(String eventId) async {
    if (!isLoggedIn) return;
    try {
      await _client.from('events').delete().eq('id', eventId);
    } catch (e) {
      debugPrint('[SyncService] Failed to delete event: $e');
      _analyticsService.log(
        AnalyticsService.syncFailed,
        AnalyticsService.error,
        properties: {'operation': 'delete_event', 'error': e.toString()},
      );
    }
  }

  Future<List<BabyEvent>> loadEventsFromSupabase(String babyId) async {
    if (!isLoggedIn) return [];
    try {
      final data = await _client
          .from('events')
          .select()
          .eq('baby_id', babyId)
          .eq('user_id', _userId!)
          .order('start_time', ascending: false);
      return (data as List).map((json) => BabyEvent.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[SyncService] Failed to load events: $e');
      _analyticsService.log(
        AnalyticsService.syncFailed,
        AnalyticsService.error,
        properties: {'operation': 'load_events', 'error': e.toString()},
      );
      return [];
    }
  }

  /// Loads only completed sleep events in the requested time range.
  /// Returns null when cloud data is unavailable, so callers can use local data.
  Future<List<BabyEvent>?> loadSleepEventsSince(
    String babyId,
    DateTime since,
  ) async {
    if (!isLoggedIn) return null;
    try {
      final data = await _client
          .from('events')
          .select()
          .eq('baby_id', babyId)
          .eq('user_id', _userId!)
          .eq('type', 'sleep')
          .gte('start_time', since.toUtc().toIso8601String())
          .not('end_time', 'is', null)
          .order('start_time', ascending: false);
      return (data as List).map((json) => BabyEvent.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[SyncService] Failed to load sleep events: $e');
      _analyticsService.log(
        AnalyticsService.syncFailed,
        AnalyticsService.error,
        properties: {
          'operation': 'load_sleep_events_since',
          'error': e.toString(),
        },
      );
      return null;
    }
  }
}
