import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../data/transaction_repository.dart';
import '../models/review_entry.dart';
import '../models/transaction.dart';
import 'ledger_controller.dart';

class TransactionReviewController extends ChangeNotifier {
  TransactionReviewController({
    required TransactionRepository repository,
    required LedgerController ledgerController,
  })  : _repository = repository,
        _ledgerController = ledgerController;

  final TransactionRepository _repository;
  final LedgerController _ledgerController;

  final Map<String, ReviewEntry> _pending = <String, ReviewEntry>{};
  final Map<String, ConfirmedTransaction> _approved =
      <String, ConfirmedTransaction>{};

  bool _initialized = false;

  bool get isInitialized => _initialized;

  UnmodifiableListView<ReviewEntry> get pendingEntries =>
      UnmodifiableListView(_pending.values.toList()
        ..sort((a, b) => a.minConfidence.compareTo(b.minConfidence)));

  UnmodifiableListView<ConfirmedTransaction> get approvedEntries =>
      UnmodifiableListView(_approved.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date)));

  bool get hasPending => _pending.isNotEmpty;

  Future<void> initialize() async {
    final pendingRecords = await _repository.loadPending();
    final confirmed = await _repository.loadConfirmed();
    _pending
      ..clear()
      ..addEntries(pendingRecords.map(
        (record) => MapEntry(
          record.id,
          ReviewEntry(id: record.id, original: record.original)
            ..editedDate = record.editedDate
            ..editedType = record.editedType
            ..editedPoints = record.editedPoints
            ..editedTimeZoneOffsetMinutes =
                record.editedTimeZoneOffsetMinutes,
        ),
      ));
    _approved
      ..clear()
      ..addEntries(confirmed.map(
        (transaction) => MapEntry(transaction.uniqueHash, transaction),
      ));
    _initialized = true;
    notifyListeners();
  }

  Future<void> ingestRecognizedTransactions(
    Iterable<ParsedTransaction> items,
  ) async {
    var mutated = false;
    var ledgerDirty = false;
    for (final item in items) {
      if (_approved.containsKey(item.uniqueHash) ||
          _pending.containsKey(item.uniqueHash)) {
        continue;
      }
      final alreadyConfirmed = await _repository.hasConfirmed(item.uniqueHash);
      final alreadyPending = await _repository.hasPending(item.uniqueHash);
      if (alreadyConfirmed || alreadyPending) {
        continue;
      }
      if (item.needsReview) {
        final entry = ReviewEntry(id: item.uniqueHash, original: item);
        _pending[item.uniqueHash] = entry;
        await _repository.upsertPending(
          PendingReviewRecord(
            id: item.uniqueHash,
            original: item,
            editedDate: entry.editedDate,
            editedType: entry.editedType,
            editedPoints: entry.editedPoints,
            editedTimeZoneOffsetMinutes: entry.editedTimeZoneOffsetMinutes,
          ),
        );
      } else {
        final confirmed = ConfirmedTransaction(
          uniqueHash: item.uniqueHash,
          date: item.date,
          type: item.type,
          points: item.points,
          sourceId: item.sourceId,
          sourceType: item.sourceType,
          approvedAt: DateTime.now(),
          rawText: item.rawText,
          timeZoneOffsetMinutes: item.timeZoneOffsetMinutes,
        );
        _approved[item.uniqueHash] = confirmed;
        await _repository.insertConfirmed(confirmed);
        ledgerDirty = true;
      }
      mutated = true;
    }
    if (mutated) {
      notifyListeners();
    }
    if (ledgerDirty) {
      await _ledgerController.refresh();
    }
  }

  Future<void> updateEntry(
    String id, {
    DateTime? date,
    TransactionType? type,
    int? points,
  }) async {
    final entry = _pending[id];
    if (entry == null) {
      return;
    }
    var mutated = false;
    if (date != null) {
      entry.editedDate = date;
      entry.editedTimeZoneOffsetMinutes = date.timeZoneOffset.inMinutes;
      mutated = true;
    }
    if (type != null) {
      entry.editedType = type;
      mutated = true;
    }
    if (points != null && points >= 0) {
      entry.editedPoints = points;
      mutated = true;
    }
    if (!mutated) {
      return;
    }
    await _repository.upsertPending(
      PendingReviewRecord(
        id: entry.id,
        original: entry.original,
        editedDate: entry.editedDate,
        editedType: entry.editedType,
        editedPoints: entry.editedPoints,
        editedTimeZoneOffsetMinutes: entry.editedTimeZoneOffsetMinutes,
      ),
    );
    notifyListeners();
  }

  Future<bool> approveEntry(String id) async {
    final entry = _pending[id];
    if (entry == null) {
      return false;
    }
    if (entry.editedPoints <= 0) {
      return false;
    }
    final hash = entry.editedHash;
    if (_approved.containsKey(hash) ||
        await _repository.hasConfirmed(hash)) {
      return false;
    }
    final duplicatePending = _pending.entries.any((element) {
      if (element.key == id) {
        return false;
      }
      return element.value.editedHash == hash;
    });
    if (duplicatePending) {
      return false;
    }
    final confirmed = ConfirmedTransaction(
      uniqueHash: hash,
      date: entry.editedDate,
      type: entry.editedType,
      points: entry.effectivePoints,
      sourceId: entry.sourceId,
      sourceType: entry.sourceType,
      approvedAt: DateTime.now(),
      rawText: entry.rawText,
      timeZoneOffsetMinutes: entry.editedTimeZoneOffsetMinutes,
    );
    _pending.remove(id);
    _approved[hash] = confirmed;
    await _repository.removePending(id);
    await _repository.insertConfirmed(confirmed);
    notifyListeners();
    await _ledgerController.refresh();
    return true;
  }

  Future<void> reset() async {
    _pending.clear();
    _approved.clear();
    await _repository.clearAll();
    notifyListeners();
    await _ledgerController.refresh();
  }
}
