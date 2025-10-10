import 'package:flutter/foundation.dart';

import '../data/transaction_repository.dart';
import '../ledger.dart';
import '../models/mock_data.dart';

class LedgerController extends ChangeNotifier {
  LedgerController({
    required TransactionRepository transactionRepository,
    FifoLedger? ledger,
  })  : _transactionRepository = transactionRepository,
        _ledger = ledger ?? FifoLedger();

  final TransactionRepository _transactionRepository;
  final FifoLedger _ledger;

  LedgerReplayResult _state =
      LedgerReplayResult(lots: const <LedgerLot>[], balance: 0);

  LedgerReplayResult get state => _state;

  List<LedgerEntry> get entries {
    return _state.lots.map(_mapLotToEntry).toList();
  }

  int get balance => _state.balance;

  Future<void> initialize() async {
    final confirmed = await _transactionRepository.loadConfirmed();
    _state = _ledger.replay(confirmed);
    notifyListeners();
  }

  Future<void> refresh() async {
    final confirmed = await _transactionRepository.loadConfirmed();
    _state = _ledger.replay(confirmed);
    notifyListeners();
  }

  Future<void> clear() async {
    _state = LedgerReplayResult(lots: const <LedgerLot>[], balance: 0);
    notifyListeners();
  }

  LedgerEntry _mapLotToEntry(LedgerLot lot) {
    final status = switch (lot.closureReason) {
      LedgerClosureReason.redeemed => 'Redeemed',
      LedgerClosureReason.expired => 'Expired',
      null => lot.remainingPoints <= 0 ? 'Redeemed' : 'Open',
    };
    return LedgerEntry(
      lotId: lot.lotId,
      acquiredOn: lot.acquiredOn,
      source: lot.source,
      points: lot.pointsEarned,
      status: status,
    );
  }
}
