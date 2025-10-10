import 'package:flutter/material.dart';

class PreferenceController extends ChangeNotifier {
  PreferenceController({
    ThemeMode initialThemeMode = ThemeMode.system,
    Locale? initialLocale,
  })  : _themeMode = initialThemeMode,
        _locale = initialLocale;

  ThemeMode _themeMode;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(Locale? locale) {
    if (locale == _locale) {
      return;
    }
    _locale = locale;
    notifyListeners();
  }
}
