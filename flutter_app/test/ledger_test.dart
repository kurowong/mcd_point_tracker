import 'package:test/test.dart';
import 'package:flutter_app/ledger.dart';
import 'package:flutter_app/models.dart';
import 'package:flutter_app/parse.dart';

void main() {
  test('FIFO consumption', () {
    final ledger = Ledger(today: DateTime(2023, 3, 1));
    ledger.add(Transaction(DateTime(2023, 1, 1), TransactionType.earned, 100));
    ledger.add(Transaction(DateTime(2023, 2, 1), TransactionType.earned, 50));
    ledger.add(Transaction(DateTime(2023, 3, 1), TransactionType.used, 80));
    expect(ledger.balance(), 70);
    final remaining = ledger.lots.map((lot) => lot.remaining).toList();
    expect(remaining, [20, 50]);
  });

  test('Expiry and expiring soon', () {
    final ledger = Ledger(today: DateTime(2024, 1, 20));
    ledger.add(Transaction(DateTime(2023, 1, 10), TransactionType.earned, 100));
    ledger.add(Transaction(DateTime(2023, 2, 10), TransactionType.earned, 100));
    expect(ledger.balance(), 100);
    final expired = ledger.lots.map((lot) => lot.expired).toList();
    expect(expired, [100, 0]);
    final expiring = ledger.expiringSoon(start: DateTime(2024, 1, 1));
    expect(expiring[0].total, 0); // January
    expect(expiring[1].total, 100); // February
  });

  test('Expired transaction type handling', () {
    final ledger = Ledger(today: DateTime(2024, 1, 20));
    ledger.add(Transaction(DateTime(2023, 1, 10), TransactionType.earned, 100));
    ledger.add(Transaction(DateTime(2023, 6, 10), TransactionType.expired, 50));
    // Expired transactions are recorded but don't affect FIFO logic
    expect(
      ledger.balance(),
      0,
    ); // 100 earned but expired naturally after 12 months
  });

  test('YTD calculations', () {
    final ledger = Ledger(today: DateTime(2024, 6, 15));
    ledger.add(Transaction(DateTime(2024, 1, 10), TransactionType.earned, 500));
    ledger.add(Transaction(DateTime(2024, 3, 15), TransactionType.used, 200));
    ledger.add(Transaction(DateTime(2024, 4, 20), TransactionType.earned, 300));
    ledger.add(
      Transaction(DateTime(2024, 5, 25), TransactionType.expired, 100),
    );

    final ytd = ledger.getYtdTotals();
    expect(ytd.earned, 800);
    expect(ytd.used, 200);
    expect(ytd.expired, 100);
    expect(ytd.net, 500);
  });

  test('McDonald\'s OCR text parsing', () {
    final sampleText = '''
Earned 2024-03-15 500
Used 2024-03-20 200
Expired 2024-04-10 100
Earned 2024-04-05 750
''';

    final parsed = parseOcrText(sampleText);
    expect(parsed.length, 4);

    expect(parsed[0].type, TransactionType.earned);
    expect(parsed[0].points, 500);
    expect(parsed[0].date, DateTime(2024, 3, 15));

    expect(parsed[1].type, TransactionType.used);
    expect(parsed[1].points, 200);

    expect(parsed[2].type, TransactionType.expired);
    expect(parsed[2].points, 100);

    expect(parsed[3].type, TransactionType.earned);
    expect(parsed[3].points, 750);
  });

  test('TransactionRecord model', () {
    final record = TransactionRecord(
      date: DateTime(2024, 3, 15),
      type: TransactionType.earned,
      points: 500,
      needsReview: true,
    );

    final updated = record.copyWith(needsReview: false, points: 600);
    expect(updated.needsReview, false);
    expect(updated.points, 600);
    expect(updated.date, DateTime(2024, 3, 15)); // unchanged
    expect(updated.type, TransactionType.earned); // unchanged

    final ledgerTxn = record.toLedgerTxn();
    expect(ledgerTxn.type, TransactionType.earned);
    expect(ledgerTxn.points, 500);
  });
}
