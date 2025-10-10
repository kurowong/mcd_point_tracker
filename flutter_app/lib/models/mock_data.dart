class PointSummary {
  const PointSummary({
    required this.balance,
    required this.ytdEarnings,
    required this.ytdRedemptions,
    required this.upcomingExpirations,
  });

  final int balance;
  final int ytdEarnings;
  final int ytdRedemptions;
  final List<ExpirationNotice> upcomingExpirations;
}

class ExpirationNotice {
  const ExpirationNotice({
    required this.lotId,
    required this.expiresOn,
    required this.points,
  });

  final String lotId;
  final DateTime expiresOn;
  final int points;
}

class MonthlyActivity {
  const MonthlyActivity({
    required this.month,
    required this.earned,
    required this.redeemed,
  });

  final DateTime month;
  final int earned;
  final int redeemed;
}

class LedgerEntry {
  const LedgerEntry({
    required this.lotId,
    required this.acquiredOn,
    required this.source,
    required this.points,
    required this.status,
  });

  final String lotId;
  final DateTime acquiredOn;
  final String source;
  final int points;
  final String status;
}

class DuplicateWarning {
  const DuplicateWarning({
    required this.transactionId,
    required this.occurrences,
    required this.flaggedOn,
  });

  final String transactionId;
  final int occurrences;
  final DateTime flaggedOn;
}

class ReviewItem {
  const ReviewItem({
    required this.memberId,
    required this.reason,
    required this.submittedOn,
    required this.points,
  });

  final String memberId;
  final String reason;
  final DateTime submittedOn;
  final int points;
}

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.monthlyActivity,
    required this.ledger,
    required this.duplicates,
    required this.reviewQueue,
  });

  final PointSummary summary;
  final List<MonthlyActivity> monthlyActivity;
  final List<LedgerEntry> ledger;
  final List<DuplicateWarning> duplicates;
  final List<ReviewItem> reviewQueue;
}

DashboardData createDemoData() {
  final now = DateTime.now();
  final monthlyActivity = List.generate(12, (index) {
    final month = DateTime(now.year, now.month - index, 1);
    return MonthlyActivity(
      month: month,
      earned: 1800 - index * 75,
      redeemed: 900 - index * 45,
    );
  }).reversed.toList();

  final ledger = <LedgerEntry>[
    LedgerEntry(
      lotId: 'LOT-1045',
      acquiredOn: DateTime(2024, 1, 12),
      source: 'Credit card bonus',
      points: 3500,
      status: 'Open',
    ),
    LedgerEntry(
      lotId: 'LOT-1046',
      acquiredOn: DateTime(2024, 2, 3),
      source: 'Gift card promo',
      points: 2100,
      status: 'Open',
    ),
    LedgerEntry(
      lotId: 'LOT-1037',
      acquiredOn: DateTime(2023, 11, 21),
      source: 'Store purchase',
      points: 1250,
      status: 'Redeemed',
    ),
    LedgerEntry(
      lotId: 'LOT-1039',
      acquiredOn: DateTime(2023, 12, 2),
      source: 'Restaurant',
      points: 780,
      status: 'Expiring',
    ),
  ];

  final duplicates = <DuplicateWarning>[
    DuplicateWarning(
      transactionId: 'TX-88421',
      occurrences: 2,
      flaggedOn: DateTime(2024, 2, 14),
    ),
    DuplicateWarning(
      transactionId: 'TX-88463',
      occurrences: 3,
      flaggedOn: DateTime(2024, 2, 15),
    ),
  ];

  final reviewQueue = <ReviewItem>[
    ReviewItem(
      memberId: 'MEM-2214',
      reason: 'High value redemption',
      submittedOn: DateTime(2024, 2, 16),
      points: 4200,
    ),
    ReviewItem(
      memberId: 'MEM-4450',
      reason: 'Manual adjustment',
      submittedOn: DateTime(2024, 2, 17),
      points: 1800,
    ),
  ];

  final summary = PointSummary(
    balance: 58750,
    ytdEarnings: 12500,
    ytdRedemptions: 4200,
    upcomingExpirations: [
      ExpirationNotice(
        lotId: 'LOT-1039',
        expiresOn: DateTime(2024, 3, 31),
        points: 780,
      ),
      ExpirationNotice(
        lotId: 'LOT-1028',
        expiresOn: DateTime(2024, 4, 15),
        points: 640,
      ),
    ],
  );

  return DashboardData(
    summary: summary,
    monthlyActivity: monthlyActivity,
    ledger: ledger,
    duplicates: duplicates,
    reviewQueue: reviewQueue,
  );
}

