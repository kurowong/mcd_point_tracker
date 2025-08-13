import 'dart:math' as math;

class Transaction {
  Transaction(this.date, this.type, this.points);

  final DateTime date;
  final String type; // 'Earned' or 'Used'
  final int points;
}

class Lot {
  Lot(this.earnedDate, this.original);

  final DateTime earnedDate;
  final int original;
  int consumed = 0;
  int expired = 0;

  DateTime expiry() => addMonths(earnedDate, 12);

  int get remaining => original - consumed - expired;
}

DateTime addMonths(DateTime d, int months) {
  final year = d.year + ((d.month - 1 + months) ~/ 12);
  final month = (d.month - 1 + months) % 12 + 1;
  final day = math.min(d.day, daysInMonth(year, month));
  return DateTime(year, month, day);
}

int daysInMonth(int year, int month) {
  final beginningNextMonth = month < 12
      ? DateTime(year, month + 1, 1)
      : DateTime(year + 1, 1, 1);
  return beginningNextMonth.subtract(const Duration(days: 1)).day;
}

class Ledger {
  Ledger({DateTime? today}) : today = today ?? DateTime.now();

  final DateTime today;
  final List<Transaction> transactions = [];
  List<Lot> lots = [];

  void add(Transaction txn) {
    transactions.add(txn);
    replay();
  }

  void replay() {
    lots = [];
    final ordered = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final txn in ordered) {
      _expire(txn.date);
      if (txn.type == 'Earned') {
        lots.add(Lot(txn.date, txn.points));
      } else if (txn.type == 'Used') {
        _consume(txn.points);
      }
    }
    _expire(today);
  }

  void _consume(int points) {
    var remaining = points;
    final ordered = List<Lot>.from(lots)
      ..sort((a, b) => a.earnedDate.compareTo(b.earnedDate));
    for (final lot in ordered) {
      if (lot.remaining <= 0) continue;
      final consume = math.min(remaining, lot.remaining);
      lot.consumed += consume;
      remaining -= consume;
      if (remaining == 0) break;
    }
    if (remaining > 0) {
      throw StateError('Not enough points to consume');
    }
  }

  void _expire(DateTime current) {
    for (final lot in lots) {
      final exp = lot.expiry();
      if (!exp.isAfter(current) && lot.remaining > 0) {
        lot.expired += lot.remaining;
      }
    }
  }

  int balance() => lots.fold(0, (sum, lot) => sum + lot.remaining);

  List<MapEntry<DateTime, int>> expiringSoon({DateTime? start, int months = 3}) {
    start ??= today;
    final results = <MapEntry<DateTime, int>>[];
    for (var m = 0; m < months; m++) {
      final monthStart = addMonths(DateTime(start.year, start.month, 1), m);
      final monthEnd = addMonths(monthStart, 1);
      var total = 0;
      for (final lot in lots) {
        final exp = lot.expiry();
        if (!exp.isBefore(monthStart) && exp.isBefore(monthEnd)) {
          total += lot.remaining;
        }
      }
      results.add(MapEntry(monthStart, total));
    }
    return results;
  }
}
