import 'dart:collection';

import 'package:flutter/material.dart';

import '../ingestion/raw_media_type.dart';
import '../models/transaction.dart';

class ReviewEntry {
  ReviewEntry({required this.id, required this.original})
      : editedDate = original.date,
        editedType = original.type,
        editedPoints = original.points.abs();

  final String id;
  final ParsedTransaction original;
  DateTime editedDate;
  TransactionType editedType;
  int editedPoints;

  double get minConfidence => original.minConfidence;
  bool get needsReview => original.needsReview;
  String get rawText => original.rawText;
  String get sourceId => original.sourceId;
  RawMediaType get sourceType => original.sourceType;

  int get effectivePoints {
    final value = editedPoints.abs();
    return editedType == TransactionType.used ? -value : value;
  }

  String get editedHash => transactionHash(
        editedDate,
        editedType,
        effectivePoints,
        sourceId: sourceId,
        rawText: rawText,
      );

  ReviewEntry copy() {
    return ReviewEntry(id: id, original: original)
      ..editedDate = editedDate
      ..editedType = editedType
      ..editedPoints = editedPoints;
  }
}

class TransactionReviewController extends ChangeNotifier {
  final Map<String, ReviewEntry> _pending = <String, ReviewEntry>{};
  final Map<String, ConfirmedTransaction> _approved =
      <String, ConfirmedTransaction>{};

  UnmodifiableListView<ReviewEntry> get pendingEntries =>
      UnmodifiableListView(_pending.values.toList()
        ..sort((a, b) => a.minConfidence.compareTo(b.minConfidence)));

  UnmodifiableListView<ConfirmedTransaction> get approvedEntries =>
      UnmodifiableListView(_approved.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date)));

  bool get hasPending => _pending.isNotEmpty;

  void ingestRecognizedTransactions(Iterable<ParsedTransaction> items) {
    var mutated = false;
    for (final item in items) {
      if (_approved.containsKey(item.uniqueHash) ||
          _pending.containsKey(item.uniqueHash)) {
        continue;
      }
      if (item.needsReview) {
        _pending[item.uniqueHash] = ReviewEntry(
          id: item.uniqueHash,
          original: item,
        );
      } else {
        _approved[item.uniqueHash] = ConfirmedTransaction(
          uniqueHash: item.uniqueHash,
          date: item.date,
          type: item.type,
          points: item.points,
          sourceId: item.sourceId,
          sourceType: item.sourceType,
          approvedAt: DateTime.now(),
          rawText: item.rawText,
        );
      }
      mutated = true;
    }
    if (mutated) {
      notifyListeners();
    }
  }

  void updateEntry(
    String id, {
    DateTime? date,
    TransactionType? type,
    int? points,
  }) {
    final entry = _pending[id];
    if (entry == null) {
      return;
    }
    if (date != null) {
      entry.editedDate = date;
    }
    if (type != null) {
      entry.editedType = type;
    }
    if (points != null && points >= 0) {
      entry.editedPoints = points;
    }
    notifyListeners();
  }

  bool approveEntry(String id) {
    final entry = _pending[id];
    if (entry == null) {
      return false;
    }
    if (entry.editedPoints <= 0) {
      return false;
    }
    final hash = entry.editedHash;
    if (_approved.containsKey(hash)) {
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
    _pending.remove(id);
    _approved[hash] = ConfirmedTransaction(
      uniqueHash: hash,
      date: entry.editedDate,
      type: entry.editedType,
      points: entry.effectivePoints,
      sourceId: entry.sourceId,
      sourceType: entry.sourceType,
      approvedAt: DateTime.now(),
      rawText: entry.rawText,
    );
    notifyListeners();
    return true;
  }
}
