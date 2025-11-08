import 'dart:async';

import 'package:flutter/material.dart';

import '../data/settings_repository.dart';
import '../ledger.dart';
import '../models/notification_settings.dart';
import '../services/expiration_notification_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({
    required SettingsRepository settingsRepository,
    required LedgerController ledgerController,
    ExpirationNotificationService? notificationService,
  })  : _settingsRepository = settingsRepository,
        _ledgerController = ledgerController,
        _notificationService =
            notificationService ?? ExpirationNotificationService();

  final SettingsRepository _settingsRepository;
  final LedgerController _ledgerController;
  final ExpirationNotificationService _notificationService;

  NotificationSettings _settings = const NotificationSettings(
    enabled: true,
    threshold: 5000,
  );
  ExpirationSummary _summary = const ExpirationSummary(
    nextMonthTotalPoints: 0,
    nextMonthStart: DateTime(1970, 1, 1),
  );
  DateTime? _lastThresholdAlertMonth;

  NotificationSettings get settings => _settings;
  ExpirationSummary get summary => _summary;
  bool get notificationsEnabled => _settings.enabled;
  int get threshold => _settings.threshold;
  DateTime? get lastThresholdAlertMonth => _lastThresholdAlertMonth;

  Future<void> initialize() async {
    await _notificationService.initialize();
    final enabled = await _settingsRepository.loadNotificationsEnabled();
    final threshold = await _settingsRepository.loadNotificationThreshold();
    _settings = NotificationSettings(enabled: enabled, threshold: threshold);
    _lastThresholdAlertMonth =
        await _settingsRepository.loadLastThresholdAlertMonth();
    await _refreshSchedules();
    _ledgerController.addListener(_handleLedgerChange);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (value == _settings.enabled) {
      return;
    }
    _settings = _settings.copyWith(enabled: value);
    notifyListeners();
    await _settingsRepository.saveNotificationsEnabled(value);
    await _refreshSchedules();
  }

  Future<void> setThreshold(int value) async {
    if (value <= 0) {
      value = 0;
    }
    if (value == _settings.threshold) {
      return;
    }
    _settings = _settings.copyWith(threshold: value);
    notifyListeners();
    await _settingsRepository.saveNotificationThreshold(value);
    await _refreshSchedules();
  }

  void _handleLedgerChange() {
    unawaited(_refreshSchedules());
  }

  Future<void> _refreshSchedules() async {
    final result = await _notificationService.updateSchedules(
      ledgerState: _ledgerController.state,
      settings: _settings,
      lastThresholdAlertMonth: _lastThresholdAlertMonth,
    );
    _summary = result.summary;
    if (result.triggeredThresholdMonth != null) {
      _lastThresholdAlertMonth = result.triggeredThresholdMonth;
      await _settingsRepository
          .saveLastThresholdAlertMonth(_lastThresholdAlertMonth);
    } else if (result.shouldClearStoredThreshold) {
      _lastThresholdAlertMonth = null;
      await _settingsRepository.saveLastThresholdAlertMonth(null);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ledgerController.removeListener(_handleLedgerChange);
    super.dispose();
  }
}

