import 'package:test/test.dart';
import '../lib/ledger.dart';

void main() {
  test('FIFO consumption', () {
    final ledger = Ledger(today: DateTime(2023, 3, 1));
    ledger.add(Transaction(DateTime(2023, 1, 1), 'Earned', 100));
    ledger.add(Transaction(DateTime(2023, 2, 1), 'Earned', 50));
    ledger.add(Transaction(DateTime(2023, 3, 1), 'Used', 80));
    expect(ledger.balance(), 70);
    final remaining = ledger.lots.map((lot) => lot.remaining).toList();
    expect(remaining, [20, 50]);
  });

  test('Expiry and expiring soon', () {
    final ledger = Ledger(today: DateTime(2024, 1, 20));
    ledger.add(Transaction(DateTime(2023, 1, 10), 'Earned', 100));
    ledger.add(Transaction(DateTime(2023, 2, 10), 'Earned', 100));
    expect(ledger.balance(), 100);
    final expired = ledger.lots.map((lot) => lot.expired).toList();
    expect(expired, [100, 0]);
    final expiring = ledger.expiringSoon(start: DateTime(2024, 1, 1));
    expect(expiring[0].value, 0); // January
    expect(expiring[1].value, 100); // February
  });
}
