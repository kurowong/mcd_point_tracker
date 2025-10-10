class NotificationSettings {
  const NotificationSettings({
    required this.enabled,
    required this.threshold,
  });

  final bool enabled;
  final int threshold;

  NotificationSettings copyWith({
    bool? enabled,
    int? threshold,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      threshold: threshold ?? this.threshold,
    );
  }
}

class ExpirationSummary {
  const ExpirationSummary({
    required this.nextMonthTotalPoints,
    required this.nextMonthStart,
  });

  final int nextMonthTotalPoints;
  final DateTime nextMonthStart;
}

