import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this._database);

  final Database _database;

  static const String _dbName = 'mcd_point_tracker.db';
  static const int _schemaVersion = 2;

  static Future<AppDatabase> open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    final database = await openDatabase(
      path,
      version: _schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        if (version < _schemaVersion) {
          await _migrate(db, version, _schemaVersion);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrate(db, oldVersion, newVersion);
      },
    );
    return AppDatabase._(database);
  }

  Database get instance => _database;

  Future<void> close() => _database.close();

  static Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE raw_media (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        source_path TEXT NOT NULL,
        captured_at INTEGER NOT NULL,
        time_zone_offset_minutes INTEGER NOT NULL DEFAULT 0,
        perceptual_hash TEXT NOT NULL,
        display_name TEXT,
        duration_ms INTEGER,
        frame_sample_count INTEGER NOT NULL DEFAULT 0,
        extras TEXT,
        recognized_transactions_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE review_queue (
        id TEXT PRIMARY KEY,
        original_json TEXT NOT NULL,
        edited_date INTEGER NOT NULL,
        edited_time_zone_offset_minutes INTEGER NOT NULL DEFAULT 0,
        edited_type TEXT NOT NULL,
        edited_points INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE confirmed_transactions (
        unique_hash TEXT PRIMARY KEY,
        transaction_date INTEGER NOT NULL,
        time_zone_offset_minutes INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL,
        points INTEGER NOT NULL,
        source_id TEXT NOT NULL,
        source_type TEXT NOT NULL,
        approved_at INTEGER NOT NULL,
        raw_text TEXT
      )
    ''');
  }

  static Future<void> _migrate(
    DatabaseExecutor db,
    int fromVersion,
    int toVersion,
  ) async {
    var version = fromVersion;
    while (version < toVersion) {
      switch (version) {
        case 1:
          await db.execute(
            'ALTER TABLE raw_media ADD COLUMN time_zone_offset_minutes INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE review_queue ADD COLUMN edited_time_zone_offset_minutes INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE confirmed_transactions ADD COLUMN time_zone_offset_minutes INTEGER NOT NULL DEFAULT 0',
          );
          version = 2;
          break;
        default:
          version = toVersion;
          break;
      }
    }
  }
}
