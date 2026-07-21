import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/baby.dart';
import '../utils/storage_service.dart';

class BabyProvider extends ChangeNotifier {
  List<Baby> _babies = [];
  int _currentIndex = 0;

  List<Baby> get babies => _babies;
  Baby? get currentBaby => _babies.isEmpty ? null : _babies[_currentIndex];
  int get currentIndex => _currentIndex;

  void loadBabies() {
    _babies = StorageService.loadBabies();
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> removeBaby(String id) async {
    _babies.removeWhere((b) => b.id == id);
    if (_currentIndex >= _babies.length) {
      _currentIndex = _babies.length - 1;
    }
    await StorageService.saveBabies(_babies);
    notifyListeners();
  }

  void setCurrentBaby(int index) {
    if (index >= 0 && index < _babies.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
