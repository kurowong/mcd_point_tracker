import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../ledger.dart';
import '../models/notification_settings.dart';

class ExpirationScheduleResult {
  const ExpirationScheduleResult({
    required this.summary,
    this.triggeredThresholdMonth,
    this.shouldClearStoredThreshold = false,
  });

  final ExpirationSummary summary;
  final DateTime? triggeredThresholdMonth;
  final bool shouldClearStoredThreshold;
}

class ExpirationNotificationService {
  ExpirationNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    tz.Location? location,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _location = location;

  static const String _mytTimeZone = 'Asia/Kuala_Lumpur';
  static const int _thresholdNotificationId = 0x0ffffffe;
  static const Duration _lotLifetime = Duration(days: 365);
  static const Duration _reminderLeadTime = Duration(days: 14);

  final FlutterLocalNotificationsPlugin _plugin;
  tz.Location? _location;
  bool _initialized = false;

  tz.Location get _tzLocation {
    _location ??= tz.getLocation(_mytTimeZone);
    return _location!;
  }

  Future<void> initialize() async {
    if (!_initialized) {
      tz.initializeTimeZones();
      _location ??= tz.getLocation(_mytTimeZone);
      tz.setLocalLocation(_location!);
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: false,
          requestSoundPermission: true,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: false,
          requestSoundPermission: true,
        ),
      );
      await _plugin.initialize(initializationSettings);

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
      _initialized = true;
    }
  }

  Future<ExpirationScheduleResult> updateSchedules({
    required LedgerReplayResult ledgerState,
    required NotificationSettings settings,
    DateTime? lastThresholdAlertMonth,
  }) async {
    final location = _tzLocation;
    final now = tz.TZDateTime.now(location);
    final nextMonthStartTz = tz.TZDateTime(location, now.year, now.month + 1, 1);
    final nextMonthStart = DateTime(
      nextMonthStartTz.year,
      nextMonthStartTz.month,
      nextMonthStartTz.day,
    );

    final openLots = ledgerState.lots
        .where((lot) =>
            !lot.isClosed && lot.remainingPoints > 0 && lot.pointsEarned > 0)
        .toList();

    final lotExpiries = <String, tz.TZDateTime>{};
    var nextMonthTotal = 0;
    for (final lot in openLots) {
      final expiry = _expiryForLot(lot, location);
      lotExpiries[lot.lotId] = expiry;
      if (expiry.year == nextMonthStart.year &&
          expiry.month == nextMonthStart.month) {
        nextMonthTotal += max(0, lot.remainingPoints);
      }
    }

    if (!settings.enabled) {
      await _cancelManagedNotifications();
      return ExpirationScheduleResult(
        summary: ExpirationSummary(
          nextMonthTotalPoints: nextMonthTotal,
          nextMonthStart: nextMonthStart,
        ),
        shouldClearStoredThreshold: lastThresholdAlertMonth != null,
      );
    }

    final scheduledLotIds = <int>{};

    final perLotDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'lot_expiration',
        'Lot expiration alerts',
        channelDescription:
            'Reminders when individual point lots approach expiration.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(presentBadge: false),
      macOS: const DarwinNotificationDetails(presentBadge: false),
    );

    for (final lot in openLots) {
      final expiry = lotExpiries[lot.lotId];
      if (expiry == null) {
        continue;
      }

      final reminder = _reminderForExpiry(expiry, location);
      if (reminder == null || !reminder.isAfter(now)) {
        continue;
      }

      final id = _notificationIdForLot(lot.lotId);
      scheduledLotIds.add(id);
      final formattedDate = DateFormat.yMMMMd().format(expiry.toLocal());
      final message =
          '${max(0, lot.remainingPoints)} points from ${lot.lotId} will expire on $formattedDate.';

      await _plugin.zonedSchedule(
        id,
        'Points expiring soon',
        message,
        reminder,
        perLotDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'lot|${lot.lotId}',
      );
    }

    await _cleanupObsoleteLotNotifications(scheduledLotIds);

    final summary = ExpirationSummary(
      nextMonthTotalPoints: nextMonthTotal,
      nextMonthStart: nextMonthStart,
    );

    final thresholdDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'expiration_threshold',
        'Upcoming expiration thresholds',
        channelDescription:
            'Alerts when points expiring next month exceed configured limits.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(presentBadge: false),
      macOS: const DarwinNotificationDetails(presentBadge: false),
    );

    final hasTriggeredThisMonth = lastThresholdAlertMonth != null &&
        lastThresholdAlertMonth.year == nextMonthStart.year &&
        lastThresholdAlertMonth.month == nextMonthStart.month;

    if (nextMonthTotal > settings.threshold && !hasTriggeredThisMonth) {
      final formattedTotal = NumberFormat.decimalPattern()
          .format(max(0, nextMonthTotal));
      final formattedMonth = DateFormat.yMMMM().format(summary.nextMonthStart);
      await _plugin.show(
        _thresholdNotificationId,
        'Large expiration incoming',
        '$formattedTotal points are due to expire in $formattedMonth.',
        thresholdDetails,
        payload: 'threshold|${summary.nextMonthStart.toIso8601String()}',
      );
      return ExpirationScheduleResult(
        summary: summary,
        triggeredThresholdMonth: summary.nextMonthStart,
      );
    }

    if (nextMonthTotal <= settings.threshold && hasTriggeredThisMonth) {
      return ExpirationScheduleResult(
        summary: summary,
        shouldClearStoredThreshold: true,
      );
    }

    return ExpirationScheduleResult(summary: summary);
  }

  tz.TZDateTime _expiryForLot(LedgerLot lot, tz.Location location) {
    final expiry = lot.acquiredOn.add(_lotLifetime);
    return tz.TZDateTime.from(expiry, location);
  }

  tz.TZDateTime? _reminderForExpiry(
    tz.TZDateTime expiry,
    tz.Location location,
  ) {
    final reminder = tz.TZDateTime(
      location,
      expiry.year,
      expiry.month,
      expiry.day,
      9,
    ).subtract(_reminderLeadTime);
    return reminder;
  }

  int _notificationIdForLot(String lotId) {
    return lotId.hashCode & 0x7fffffff;
  }

  Future<void> _cleanupObsoleteLotNotifications(Set<int> activeIds) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith('lot|') ?? false) {
        if (!activeIds.contains(request.id)) {
          await _plugin.cancel(request.id);
        }
      }
    }
  }

  Future<void> _cancelManagedNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload ?? '';
      if (payload.startsWith('lot|') || payload.startsWith('threshold|')) {
        await _plugin.cancel(request.id);
      }
    }
  }
}

