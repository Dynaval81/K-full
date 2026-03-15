import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('de');

  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale');
    if (saved != null) {
      _locale = Locale(saved);
    } else {
      const supported = {'de', 'en', 'ru'};
      final systemCode =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      _locale = Locale(supported.contains(systemCode) ? systemCode : 'de');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }
}
