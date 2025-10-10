import 'models/transaction.dart';

enum LedgerClosureReason { redeemed, expired }

class LedgerLot {
  LedgerLot({
    required this.lotId,
    required this.acquiredOn,
    required this.source,
    required this.pointsEarned,
    required this.timeZoneOffsetMinutes,
  }) : remainingPoints = pointsEarned;

  final String lotId;
  final DateTime acquiredOn;
  final String source;
  final int pointsEarned;
  final int timeZoneOffsetMinutes;

  int remainingPoints;
  LedgerClosureReason? closureReason;
  DateTime? closedOn;

  bool get isClosed => remainingPoints <= 0 || closureReason != null;
}

class LedgerReplayResult {
  LedgerReplayResult({required this.lots, required this.balance});

  final List<LedgerLot> lots;
  final int balance;
}

class FifoLedger {
  LedgerReplayResult replay(Iterable<ConfirmedTransaction> transactions) {
    final lots = <LedgerLot>[];
    final openLots = <LedgerLot>[];
    final sorted = transactions.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final transaction in sorted) {
      switch (transaction.type) {
        case TransactionType.earned:
          final lot = LedgerLot(
            lotId: transaction.uniqueHash.substring(0, 8).toUpperCase(),
            acquiredOn: transaction.date,
            source: transaction.sourceType.name,
            pointsEarned: transaction.points.abs(),
            timeZoneOffsetMinutes: transaction.timeZoneOffsetMinutes,
          );
          lots.add(lot);
          openLots.add(lot);
          break;
        case TransactionType.used:
        case TransactionType.expired:
          _applyDebit(
            openLots,
            transaction,
            lots,
            transaction.type == TransactionType.used
                ? LedgerClosureReason.redeemed
                : LedgerClosureReason.expired,
          );
          break;
      }
    }

    final balance = lots.fold<int>(
      0,
      (total, lot) => total + lot.remainingPoints.clamp(0, lot.pointsEarned),
    );
    return LedgerReplayResult(lots: lots, balance: balance);
  }

  void _applyDebit(
    List<LedgerLot> openLots,
    ConfirmedTransaction transaction,
    List<LedgerLot> allLots,
    LedgerClosureReason reason,
  ) {
    var remaining = transaction.points.abs();
    if (remaining <= 0) {
      return;
    }
    final iterator = openLots.iterator;
    while (remaining > 0 && iterator.moveNext()) {
      final lot = iterator.current;
      if (lot.remainingPoints <= 0) {
        continue;
      }
      final deduction = remaining > lot.remainingPoints
          ? lot.remainingPoints
          : remaining;
      lot.remainingPoints -= deduction;
      remaining -= deduction;
      if (lot.remainingPoints <= 0) {
        lot.closureReason = reason;
        lot.closedOn = transaction.date;
      }
    }
    openLots.removeWhere((lot) => lot.remainingPoints <= 0);
    if (remaining > 0) {
      // Record negative balance as a synthetic lot to highlight deficit.
      final deficitLot = LedgerLot(
        lotId: 'DEF-${transaction.uniqueHash.substring(0, 5).toUpperCase()}',
        acquiredOn: transaction.date,
        source: transaction.sourceType.name,
        pointsEarned: 0,
        timeZoneOffsetMinutes: transaction.timeZoneOffsetMinutes,
      )
        ..remainingPoints = -remaining
        ..closureReason = reason
        ..closedOn = transaction.date;
      allLots.add(deficitLot);
    }
  }
}
