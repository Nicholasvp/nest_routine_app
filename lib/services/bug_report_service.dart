import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class BugReportService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService;

  BugReportService(this._authService);

  Future<void> submitBugReport({
    required String title,
    required String description,
    String? email,
    String? appVersion,
    String? platform,
  }) async {
    final userId = _authService.userId;

    await _client.from('bug_reports').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'email': email,
      'app_version': appVersion,
      'platform': platform,
    });
  }
}
