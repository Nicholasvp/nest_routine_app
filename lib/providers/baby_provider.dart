import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/baby.dart';
import '../utils/storage_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/analytics_service.dart';
import '../services/meta_ads_service.dart';

class BabyProvider extends ChangeNotifier {
  List<Baby> _babies = [];
  int _currentIndex = 0;
  SyncService? _syncService;
  AnalyticsService? _analyticsService;

  List<Baby> get babies => _babies;
  Baby? get currentBaby => _babies.isEmpty ? null : _babies[_currentIndex];
  int get currentIndex => _currentIndex;

  void initSyncService(AuthService authService) {
    _syncService = SyncService(authService);
    _analyticsService = AnalyticsService(authService);
  }

  void loadBabies() {
    _babies = StorageService.loadBabies();
    notifyListeners();
  }

  void clearBabies() {
    _babies = [];
    _currentIndex = 0;
    StorageService.saveBabies(_babies);
    notifyListeners();
  }

  /// Pushes any babies created while offline to the cloud, then pulls the
  /// cloud down and unions the two so local-only babies are never dropped.
  Future<void> loadBabiesFromCloud() async {
    if (_syncService == null || !_syncService!.isLoggedIn) return;

    final userId = _syncService!.userId;
    if (userId != null) {
      await _syncService!.migrateLocalDataToCloud(userId);
    }

    final cloudBabies = await _syncService!.loadBabiesFromSupabase();
    if (cloudBabies.isEmpty) return;

    _babies = _mergeBabies(StorageService.loadBabies(), cloudBabies);
    if (_currentIndex >= _babies.length) {
      _currentIndex = _babies.isEmpty ? 0 : _babies.length - 1;
    }
    await StorageService.saveBabies(_babies);
    notifyListeners();
  }

  /// Union by id: the cloud is authoritative for babies that exist in both,
  /// while babies that only exist locally are kept.
  List<Baby> _mergeBabies(List<Baby> local, List<Baby> cloud) {
    if (local.isEmpty) return cloud;
    final pending = local
        .where((localBaby) => cloud.every((c) => c.id != localBaby.id))
        .toList();
    return [...cloud, ...pending]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> addBaby(String name, DateTime dateOfBirth, {String? photoPath}) async {
    final baby = Baby(
      id: const Uuid().v4(),
      name: name,
      dateOfBirth: dateOfBirth,
      photoPath: photoPath,
    );
    _babies.add(baby);
    _currentIndex = _babies.length - 1;
    await StorageService.saveBabies(_babies);
    _syncService?.syncBabyToSupabase(baby);
    _analyticsService?.log(AnalyticsService.addBaby, AnalyticsService.usage, properties: {
      'baby_id': baby.id,
      'baby_name': baby.name,
    });
    MetaAdsService.instance.logAddBaby();
    notifyListeners();
  }

  Future<void> updateBaby(String id, {String? name, DateTime? dateOfBirth, String? photoPath}) async {
    final index = _babies.indexWhere((b) => b.id == id);
    if (index == -1) return;
    _babies[index] = _babies[index].copyWith(
      name: name,
      dateOfBirth: dateOfBirth,
      photoPath: photoPath,
    );
    await StorageService.saveBabies(_babies);
    _syncService?.syncBabyToSupabase(_babies[index]);
    notifyListeners();
  }

  Future<void> removeBaby(String id) async {
    _babies.removeWhere((b) => b.id == id);
    if (_currentIndex >= _babies.length) {
      _currentIndex = _babies.length - 1;
    }
    await StorageService.saveBabies(_babies);
    _syncService?.deleteBabyFromSupabase(id);
    _analyticsService?.log(AnalyticsService.removeBaby, AnalyticsService.usage, properties: {
      'baby_id': id,
    });
    notifyListeners();
  }

  void setCurrentBaby(int index) {
    if (index >= 0 && index < _babies.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
