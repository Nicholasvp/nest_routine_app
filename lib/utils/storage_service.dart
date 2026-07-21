import 'package:hive_flutter/hive_flutter.dart';
import '../models/baby.dart';
import '../models/event.dart';

class StorageService {
  static late Box _settingsBox;
  static late Box _babiesBox;
  static late Box _eventsBox;

  static Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
    _babiesBox = await Hive.openBox('babies');
    _eventsBox = await Hive.openBox('events');
  }

  static bool get isOnboardingComplete =>
      _settingsBox.get('onboarding_complete', defaultValue: false) as bool;

  static Future<void> setOnboardingComplete(bool value) async {
    await _settingsBox.put('onboarding_complete', value);
  }

  static String? getLocale() => _settingsBox.get('locale') as String?;

  static Future<void> setLocale(String code) async {
    await _settingsBox.put('locale', code);
  }

  static List<Baby> loadBabies() {
    final data = _babiesBox.get('all');
    if (data == null) return [];
    return List<Baby>.from(data as List);
  }

  static Future<void> saveBabies(List<Baby> babies) async {
    await _babiesBox.put('all', babies);
  }

  static List<BabyEvent> loadEvents(String babyId) {
    final data = _eventsBox.get(babyId);
    if (data == null) return [];
    return List<BabyEvent>.from(data as List);
  }

  static Future<void> saveEvents(String babyId, List<BabyEvent> events) async {
    await _eventsBox.put(babyId, events);
  }

  static Map<String, dynamic>? loadNotificationSettings() {
    final data = _settingsBox.get('notification_settings');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    await _settingsBox.put('notification_settings', settings);
  }
}
