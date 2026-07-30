import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/baby.dart';
import '../models/event.dart';
import 'auth_service.dart';

class SyncService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService;

  SyncService(this._authService);

  String? get _userId => _authService.userId;

  bool get isLoggedIn => _authService.isLoggedIn;

  // ── Babies ──

  Future<void> syncBabyToSupabase(Baby baby) async {
    if (!isLoggedIn) return;
    await _client.from('babies').upsert({
      'id': baby.id,
      'user_id': _userId,
      'name': baby.name,
      'photo_path': baby.photoPath,
      'date_of_birth': baby.dateOfBirth.toIso8601String(),
      'created_at': baby.createdAt.toIso8601String(),
    });
  }

  Future<void> deleteBabyFromSupabase(String babyId) async {
    if (!isLoggedIn) return;
    await _client.from('babies').delete().eq('id', babyId);
  }

  Future<List<Baby>> loadBabiesFromSupabase() async {
    if (!isLoggedIn) return [];
    final data = await _client
        .from('babies')
        .select()
        .eq('user_id', _userId!)
        .order('created_at');
    return (data as List).map((json) => Baby.fromJson(json)).toList();
  }

  // ── Events ──

  Future<void> syncEventToSupabase(BabyEvent event) async {
    if (!isLoggedIn) return;
    await _client.from('events').upsert({
      'id': event.id,
      'baby_id': event.babyId,
      'user_id': _userId,
      'type': event.type.name,
      'start_time': event.startTime.toIso8601String(),
      'end_time': event.endTime?.toIso8601String(),
      'notes': event.notes,
      'feed_type': event.feedType?.name,
      'feed_side': event.feedSide?.name,
      'duration_minutes': event.durationMinutes,
      'volume_ml': event.volumeMl,
      'has_pee': event.hasPee,
      'has_poop': event.hasPoop,
      'diaper_texture': event.diaperTexture?.name,
    });
  }

  Future<void> deleteEventFromSupabase(String eventId) async {
    if (!isLoggedIn) return;
    await _client.from('events').delete().eq('id', eventId);
  }

  Future<List<BabyEvent>> loadEventsFromSupabase(String babyId) async {
    if (!isLoggedIn) return [];
    final data = await _client
        .from('events')
        .select()
        .eq('baby_id', babyId)
        .eq('user_id', _userId!)
        .order('start_time', ascending: false);
    return (data as List).map((json) => BabyEvent.fromJson(json)).toList();
  }

  // ── Bulk sync (first login) ──

  Future<void> bulkSyncBabies(List<Baby> localBabies) async {
    if (!isLoggedIn) return;
    for (final baby in localBabies) {
      await syncBabyToSupabase(baby);
    }
  }

  Future<void> bulkSyncEvents(String babyId, List<BabyEvent> localEvents) async {
    if (!isLoggedIn) return;
    for (final event in localEvents) {
      await syncEventToSupabase(event);
    }
  }
}
