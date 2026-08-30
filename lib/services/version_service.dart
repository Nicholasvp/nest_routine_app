import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VersionInfo {
  final bool hasUpdate;
  final bool isForceUpdate;
  final String latestVersion;
  final String minVersion;
  final String? releaseNotes;
  final String? storeUrl;

  const VersionInfo({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.latestVersion,
    required this.minVersion,
    this.releaseNotes,
    this.storeUrl,
  });

  static const empty = VersionInfo(
    hasUpdate: false,
    isForceUpdate: false,
    latestVersion: '',
    minVersion: '',
  );
}

class VersionService {
  VersionService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<VersionInfo> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      Map<String, dynamic>? response;

      try {
        response = await _client
            .from('app_versions')
            .select()
            .eq('platform', platform)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      } catch (_) {
        // ignore, will try 'all' next
      }

      response ??= await _client
          .from('app_versions')
          .select()
          .eq('platform', 'all')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response.isEmpty) {
        return VersionInfo.empty;
      }

      final latestVersion = response['latest_version']?.toString();
      final minVersion = response['min_version']?.toString();

      if (latestVersion == null || minVersion == null) {
        return VersionInfo.empty;
      }

      final isForceUpdate = response['is_force_update'] == true;
      final releaseNotes = response['release_notes']?.toString();
      final storeUrl = response['store_url']?.toString();

      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);
      final min = _parseVersion(minVersion);

      if (current.isEmpty || latest.isEmpty) {
        return VersionInfo.empty;
      }

      final hasUpdate = _isNewer(latest, current);
      final isBelowMin = min.isNotEmpty && _isNewer(min, current);

      if (!hasUpdate && !isBelowMin) {
        return VersionInfo.empty;
      }

      return VersionInfo(
        hasUpdate: true,
        isForceUpdate: isForceUpdate || isBelowMin,
        latestVersion: latestVersion,
        minVersion: minVersion,
        releaseNotes: releaseNotes,
        storeUrl: storeUrl,
      );
    } catch (e) {
      debugPrint('[VersionService] Failed to check for update: $e');
      return VersionInfo.empty;
    }
  }

  static List<int> _parseVersion(String version) {
    final cleaned = version.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = cleaned.split('.');
    return parts.map(int.tryParse).whereType<int>().toList();
  }

  static bool _isNewer(List<int> target, List<int> current) {
    final maxLen = target.length > current.length ? target.length : current.length;
    for (var i = 0; i < maxLen; i++) {
      final t = i < target.length ? target[i] : 0;
      final c = i < current.length ? current[i] : 0;
      if (t > c) return true;
      if (t < c) return false;
    }
    return false;
  }
}
