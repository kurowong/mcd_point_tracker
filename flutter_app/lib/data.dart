import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';
import 'ledger.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docs.path, 'mcd_point_tracker.db');
    _db = await openDatabase(dbPath, version: 1, onCreate: _onCreate);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        points INTEGER NOT NULL,
        needs_review INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.execute(
      'CREATE INDEX idx_txn_dtp ON transactions(date, type, points);',
    );
  }
}

class TransactionsDao {
  TransactionsDao(this._db);

  final Future<Database> _db;

  Future<List<TransactionRecord>> getAll() async {
    final db = await _db;
    final rows = await db.query('transactions', orderBy: 'date ASC, id ASC');
    return rows.map(_fromRow).toList();
  }

  Future<List<TransactionRecord>> getNeedsReview() async {
    final db = await _db;
    final rows = await db.query(
      'transactions',
      where: 'needs_review = 1',
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> upsert(TransactionRecord record) async {
    final db = await _db;
    final existing = await db.query(
      'transactions',
      where: 'date = ? AND type = ? AND points = ?',
      whereArgs: [
        record.date.toIso8601String().substring(0, 10),
        _typeToString(record.type),
        record.points,
      ],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'transactions',
        {'needs_review': record.needsReview ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }
    return await db.insert('transactions', _toRow(record));
  }

  Future<List<int>> upsertBatch(List<TransactionRecord> records) async {
    final db = await _db;
    final ids = <int>[];

    await db.transaction((txn) async {
      for (final record in records) {
        final existing = await txn.query(
          'transactions',
          where: 'date = ? AND type = ? AND points = ?',
          whereArgs: [
            record.date.toIso8601String().substring(0, 10),
            _typeToString(record.type),
            record.points,
          ],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final id = existing.first['id'] as int;
          await txn.update(
            'transactions',
            {'needs_review': record.needsReview ? 1 : 0},
            where: 'id = ?',
            whereArgs: [id],
          );
          ids.add(id);
        } else {
          final id = await txn.insert('transactions', _toRow(record));
          ids.add(id);
        }
      }
    });

    return ids;
  }

  Future<void> updateRecord(TransactionRecord record) async {
    final db = await _db;
    if (record.id == null) return;
    await db.update(
      'transactions',
      _toRow(record),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('transactions');
  }

  Map<String, Object?> _toRow(TransactionRecord r) => {
    'id': r.id,
    'date': r.date.toIso8601String().substring(0, 10),
    'type': _typeToString(r.type),
    'points': r.points,
    'needs_review': r.needsReview ? 1 : 0,
  }..removeWhere((key, value) => value == null);

  TransactionRecord _fromRow(Map<String, Object?> row) {
    final typeStr = row['type'] as String;
    return TransactionRecord(
      id: row['id'] as int?,
      date: DateTime.parse(row['date'] as String),
      type: _stringToType(typeStr),
      points: row['points'] as int,
      needsReview: (row['needs_review'] as int) == 1,
    );
  }

  String _typeToString(TransactionType t) {
    switch (t) {
      case TransactionType.earned:
        return 'Earned';
      case TransactionType.used:
        return 'Used';
      case TransactionType.expired:
        return 'Expired';
    }
  }

  TransactionType _stringToType(String s) {
    switch (s) {
      case 'Earned':
        return TransactionType.earned;
      case 'Used':
        return TransactionType.used;
      case 'Expired':
        return TransactionType.expired;
      default:
        return TransactionType.used; // fallback
    }
  }
}
