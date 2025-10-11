from __future__ import annotations

"""FIFO lot ledger logic for McD Point Tracker."""

from dataclasses import dataclass, field
from datetime import date
from calendar import monthrange
from typing import List


@dataclass(frozen=True)
class Transaction:
    """A single points transaction."""

    date: date
    type: str  # 'Earned', 'Used'
    points: int


@dataclass
class Lot:
    earned_date: date
    original: int
    consumed: int = 0
    expired: int = 0

    def expiry(self) -> date:
        return add_months(self.earned_date, 12)

    @property
    def remaining(self) -> int:
        return self.original - self.consumed - self.expired


def add_months(d: date, months: int) -> date:
    """Return a date `months` after `d` handling varying month lengths."""

    year = d.year + (d.month - 1 + months) // 12
    month = (d.month - 1 + months) % 12 + 1
    day = min(d.day, monthrange(year, month)[1])
    return date(year, month, day)


class Ledger:
    """FIFO ledger managing earned lots and consumption."""

    def __init__(self, today: date | None = None) -> None:
        self.today = today or date.today()
        self.lots: List[Lot] = []
        self.transactions: List[Transaction] = []

    def add(self, txn: Transaction) -> None:
        """Add a transaction and replay the ledger."""
        self.transactions.append(txn)
        self.replay()

    # core replay
    def replay(self) -> None:
        self.lots = []
        for txn in sorted(self.transactions, key=lambda t: t.date):
            self._expire(txn.date)
            if txn.type == "Earned":
                self.lots.append(Lot(txn.date, txn.points))
            elif txn.type == "Used":
                self._consume(txn.points)
        self._expire(self.today)

    def _consume(self, points: int) -> None:
        remaining = points
        for lot in sorted(self.lots, key=lambda l: l.earned_date):
            if lot.remaining <= 0:
                continue
            consume = min(remaining, lot.remaining)
            lot.consumed += consume
            remaining -= consume
            if remaining == 0:
                break
        if remaining:
            raise ValueError("Not enough points to consume")

    def _expire(self, current: date) -> None:
        for lot in self.lots:
            if lot.expiry() <= current and lot.remaining > 0:
                lot.expired += lot.remaining

    def balance(self) -> int:
        return sum(lot.remaining for lot in self.lots)

    def expiring_soon(self, start: date | None = None, months: int = 3) -> List[tuple[date, int]]:
        """Return totals of points expiring per month for the next `months` months."""
        start = start or self.today
        results: List[tuple[date, int]] = []
        for m in range(months):
            month_start = add_months(start.replace(day=1), m)
            month_end = add_months(month_start, 1)
            total = 0
            for lot in self.lots:
                if month_start <= lot.expiry() < month_end:
                    total += lot.remaining
            results.append((month_start, total))
        return results
