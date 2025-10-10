import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../ingestion/raw_media_type.dart';
import '../models/transaction.dart';

class PendingReviewRecord {
  PendingReviewRecord({
    required this.id,
    required this.original,
    required this.editedDate,
    required this.editedType,
    required this.editedPoints,
    required this.editedTimeZoneOffsetMinutes,
  });

  final String id;
  final ParsedTransaction original;
  final DateTime editedDate;
  final TransactionType editedType;
  final int editedPoints;
  final int editedTimeZoneOffsetMinutes;
}

class TransactionRepository {
  TransactionRepository(this._database);

  final Database _database;

  Future<List<PendingReviewRecord>> loadPending() async {
    final rows = await _database.query('review_queue');
    return rows.map(_mapPending).toList();
  }

  Future<List<ConfirmedTransaction>> loadConfirmed() async {
    final rows = await _database.query(
      'confirmed_transactions',
      orderBy: 'transaction_date ASC, approved_at ASC',
    );
    return rows.map(_mapConfirmed).toList();
  }

  Future<void> upsertPending(PendingReviewRecord record) async {
    await _database.insert(
      'review_queue',
      {
        'id': record.id,
        'original_json': jsonEncode(record.original.toJson()),
        'edited_date': record.editedDate.toUtc().millisecondsSinceEpoch,
        'edited_time_zone_offset_minutes': record.editedTimeZoneOffsetMinutes,
        'edited_type': record.editedType.name,
        'edited_points': record.editedPoints,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removePending(String id) async {
    await _database.delete('review_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasPending(String id) async {
    final result = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(1) FROM review_queue WHERE id = ?',
        [id],
      ),
    );
    return (result ?? 0) > 0;
  }

  Future<void> insertConfirmed(ConfirmedTransaction transaction) async {
    await _database.insert(
      'confirmed_transactions',
      {
        'unique_hash': transaction.uniqueHash,
        'transaction_date':
            transaction.date.toUtc().millisecondsSinceEpoch,
        'time_zone_offset_minutes': transaction.timeZoneOffsetMinutes,
        'type': transaction.type.name,
        'points': transaction.points,
        'source_id': transaction.sourceId,
        'source_type': transaction.sourceType.name,
        'approved_at': transaction.approvedAt.toUtc().millisecondsSinceEpoch,
        'raw_text': transaction.rawText,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> hasConfirmed(String uniqueHash) async {
    final result = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(1) FROM confirmed_transactions WHERE unique_hash = ?',
        [uniqueHash],
      ),
    );
    return (result ?? 0) > 0;
  }

  Future<void> clearAll() async {
    await _database.delete('review_queue');
    await _database.delete('confirmed_transactions');
  }

  PendingReviewRecord _mapPending(Map<String, Object?> row) {
    final originalJson = row['original_json'] as String;
    final originalMap = jsonDecode(originalJson) as Map<String, dynamic>;
    final original = ParsedTransaction.fromJson(originalMap);
    final editedDateUtc =
        DateTime.fromMillisecondsSinceEpoch(row['edited_date'] as int, isUtc: true);
    return PendingReviewRecord(
      id: row['id'] as String,
      original: original,
      editedDate: editedDateUtc.toLocal(),
      editedType: TransactionTypeLabel.fromString(row['edited_type'] as String),
      editedPoints: row['edited_points'] as int,
      editedTimeZoneOffsetMinutes:
          row['edited_time_zone_offset_minutes'] as int? ??
              original.timeZoneOffsetMinutes,
    );
  }

  ConfirmedTransaction _mapConfirmed(Map<String, Object?> row) {
    final dateUtc = DateTime.fromMillisecondsSinceEpoch(
      row['transaction_date'] as int,
      isUtc: true,
    );
    final approvedAtUtc = DateTime.fromMillisecondsSinceEpoch(
      row['approved_at'] as int,
      isUtc: true,
    );
    final offsetMinutes = row['time_zone_offset_minutes'] as int? ?? 0;
    final offset = Duration(minutes: offsetMinutes);
    final restoredDate = dateUtc.add(offset);
    final restoredApprovedAt = approvedAtUtc.add(offset);
    return ConfirmedTransaction(
      uniqueHash: row['unique_hash'] as String,
      date: restoredDate,
      type: TransactionTypeLabel.fromString(row['type'] as String),
      points: row['points'] as int,
      sourceId: row['source_id'] as String,
      sourceType: RawMediaType.values.firstWhere(
        (value) => value.name == row['source_type'],
        orElse: () => RawMediaType.screenshot,
      ),
      approvedAt: restoredApprovedAt,
      rawText: row['raw_text'] as String? ?? '',
      timeZoneOffsetMinutes: offsetMinutes,
    );
  }
}
