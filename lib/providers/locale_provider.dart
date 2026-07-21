import 'package:flutter/material.dart';
import '../utils/storage_service.dart';
import '../utils/strings.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isPortuguese => _locale.languageCode == 'pt';
  Strings get strings => isPortuguese ? Strings.pt() : Strings();

  Future<void> loadLocale() async {
    final saved = StorageService.getLocale();
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    await StorageService.setLocale(languageCode);
    notifyListeners();
  }

  void toggle() {
    setLocale(isPortuguese ? 'en' : 'pt');
  }
}
