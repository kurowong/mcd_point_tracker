from datetime import date

from point_tracker.ledger import Ledger, Transaction


def test_fifo_consumption():
    ledger = Ledger(today=date(2023, 3, 1))
    ledger.add(Transaction(date(2023, 1, 1), "Earned", 100))
    ledger.add(Transaction(date(2023, 2, 1), "Earned", 50))
    ledger.add(Transaction(date(2023, 3, 1), "Used", 80))
    assert ledger.balance() == 70
    # first lot should have 20 remaining, second lot 50
    remaining = [lot.remaining for lot in ledger.lots]
    assert remaining == [20, 50]


def test_expiry_and_expiring_soon():
    ledger = Ledger(today=date(2024, 1, 20))
    ledger.add(Transaction(date(2023, 1, 10), "Earned", 100))
    ledger.add(Transaction(date(2023, 2, 10), "Earned", 100))
    assert ledger.balance() == 100
    # first lot expired
    expired = [lot.expired for lot in ledger.lots]
    assert expired == [100, 0]
    expiring = ledger.expiring_soon(start=date(2024, 1, 1))
    # second lot expires Feb 10 2024, so February bucket should show 100
    assert expiring[0][1] == 0  # January
    assert expiring[1][1] == 100  # February
