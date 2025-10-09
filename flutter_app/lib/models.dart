import 'ledger.dart';

class TransactionRecord {
  TransactionRecord({
    this.id,
    required this.date,
    required this.type,
    required this.points,
    this.needsReview = false,
  });

  final int? id;
  final DateTime date;
  final TransactionType type;
  final int points;
  final bool needsReview;

  Transaction toLedgerTxn() => Transaction(date, type, points);

  TransactionRecord copyWith({
    int? id,
    DateTime? date,
    TransactionType? type,
    int? points,
    bool? needsReview,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      points: points ?? this.points,
      needsReview: needsReview ?? this.needsReview,
    );
  }
}



