import 'dart:async';

import 'package:flutter/material.dart';

import '../data/settings_repository.dart';

class PreferenceController extends ChangeNotifier {
  PreferenceController({
    required SettingsRepository repository,
    ThemeMode initialThemeMode = ThemeMode.system,
    Locale? initialLocale,
  })  : _repository = repository,
        _themeMode = initialThemeMode,
        _locale = initialLocale;

  final SettingsRepository _repository;
  ThemeMode _themeMode;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    unawaited(_repository.saveThemeMode(_themeMode));
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    unawaited(_repository.saveThemeMode(mode));
  }

  void setLocale(Locale? locale) {
    if (locale == _locale) {
      return;
    }
    _locale = locale;
    notifyListeners();
    unawaited(_repository.saveLocale(locale));
  }

  Future<void> reset() async {
    _themeMode = ThemeMode.system;
    _locale = null;
    notifyListeners();
    await _repository.clearAll();
  }
}
