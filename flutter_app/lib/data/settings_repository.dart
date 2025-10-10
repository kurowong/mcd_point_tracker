import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  SettingsRepository(this._database);

  final Database _database;

  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'preferred_locale';
  static const String _retentionKey = 'raw_media_retention_days';
  static const String _timezoneKey = 'preferred_timezone_offset';

  Future<ThemeMode> loadThemeMode({ThemeMode fallback = ThemeMode.system}) async {
    final row = await _loadValue(_themeKey);
    if (row == null) {
      return fallback;
    }
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == row,
      orElse: () => fallback,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _saveValue(_themeKey, mode.name);
  }

  Future<Locale?> loadLocale() async {
    final value = await _loadValue(_localeKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final languageCode = decoded['languageCode'] as String?;
      final countryCode = decoded['countryCode'] as String?;
      if (languageCode == null) {
        return null;
      }
      return Locale(languageCode, countryCode);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocale(Locale? locale) async {
    if (locale == null) {
      await _deleteValue(_localeKey);
      return;
    }
    await _saveValue(
      _localeKey,
      jsonEncode(<String, String?>{
        'languageCode': locale.languageCode,
        'countryCode': locale.countryCode,
      }),
    );
  }

  Future<int> loadRetentionDays({int fallback = 7}) async {
    final value = await _loadValue(_retentionKey);
    if (value == null) {
      return fallback;
    }
    return int.tryParse(value) ?? fallback;
  }

  Future<void> saveRetentionDays(int days) async {
    await _saveValue(_retentionKey, days.toString());
  }

  Future<void> savePreferredTimezoneOffset(Duration offset) async {
    await _saveValue(_timezoneKey, offset.inMinutes.toString());
  }

  Future<Duration?> loadPreferredTimezoneOffset() async {
    final value = await _loadValue(_timezoneKey);
    if (value == null) {
      return null;
    }
    final minutes = int.tryParse(value);
    if (minutes == null) {
      return null;
    }
    return Duration(minutes: minutes);
  }

  Future<void> clearAll() async {
    await _database.delete('user_settings');
  }

  Future<String?> _loadValue(String key) async {
    final rows = await _database.query(
      'user_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> _saveValue(String key, String value) async {
    await _database.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _deleteValue(String key) async {
    await _database.delete('user_settings', where: 'key = ?', whereArgs: [key]);
  }
}
