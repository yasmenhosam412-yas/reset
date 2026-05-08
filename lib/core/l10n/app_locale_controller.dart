import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static const _prefsKey = 'app_locale_code';
  static final AppLocaleController instance = AppLocaleController._();

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null || code.isEmpty) return;
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocaleCode(String code) async {
    if (code.isEmpty) return;
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    notifyListeners();
  }
}
