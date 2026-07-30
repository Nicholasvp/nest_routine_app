import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/baby.dart';
import '../utils/storage_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class BabyProvider extends ChangeNotifier {
  List<Baby> _babies = [];
  int _currentIndex = 0;
  SyncService? _syncService;

  List<Baby> get babies => _babies;
  Baby? get currentBaby => _babies.isEmpty ? null : _babies[_currentIndex];
  int get currentIndex => _currentIndex;

  void initSyncService(AuthService authService) {
    _syncService = SyncService(authService);
  }

  void loadBabies() {
    _babies = StorageService.loadBabies();
    notifyListeners();
  }

  Future<void> loadBabiesFromCloud() async {
    if (_syncService == null || !_syncService!.isLoggedIn) return;
    final cloudBabies = await _syncService!.loadBabiesFromSupabase();
    if (cloudBabies.isNotEmpty) {
      _babies = cloudBabies;
      await StorageService.saveBabies(_babies);
      notifyListeners();
    }
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
    notifyListeners();
  }

  void setCurrentBaby(int index) {
    if (index >= 0 && index < _babies.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
