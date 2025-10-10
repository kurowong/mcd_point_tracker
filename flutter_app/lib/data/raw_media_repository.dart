import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../ingestion/raw_media_metadata.dart';
import '../models/transaction.dart';

class RawMediaRepository {
  RawMediaRepository(this._database);

  final Database _database;

  Future<List<RawMediaMetadata>> loadMetadata() async {
    final rows = await _database.query(
      'raw_media',
      orderBy: 'captured_at DESC',
    );
    return rows.map(_mapMetadata).toList();
  }

  Future<void> appendMetadata(List<RawMediaMetadata> entries) async {
    final batch = _database.batch();
    for (final entry in entries) {
      batch.insert(
        'raw_media',
        {
          'id': entry.id,
          'type': entry.type.name,
          'source_path': entry.sourcePath,
          'captured_at': entry.capturedAt.toUtc().millisecondsSinceEpoch,
          'time_zone_offset_minutes': entry.timeZoneOffsetMinutes,
          'perceptual_hash': entry.perceptualHash,
          'display_name': entry.displayName,
          'duration_ms': entry.duration?.inMilliseconds,
          'frame_sample_count': entry.frameSampleCount,
          'extras': jsonEncode(entry.extras),
          'recognized_transactions_json': jsonEncode(
            entry.recognizedTransactions
                .map((transaction) => transaction.toJson())
                .toList(),
          ),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> cleanupExpired(Duration retention) async {
    final threshold = DateTime.now().subtract(retention).toUtc();
    final rows = await _database.query(
      'raw_media',
      where: 'captured_at < ?',
      whereArgs: [threshold.millisecondsSinceEpoch],
    );
    var removed = 0;
    final batch = _database.batch();
    for (final row in rows) {
      batch.delete('raw_media', where: 'id = ?', whereArgs: [row['id']]);
      removed++;
      final path = row['source_path'] as String?;
      if (path != null && path.isNotEmpty) {
        unawaited(File(path).delete().catchError((_) {}));
      }
    }
    await batch.commit(noResult: true);
    return removed;
  }

  Future<void> saveMetadata(List<RawMediaMetadata> entries) async {
    await _database.delete('raw_media');
    await appendMetadata(entries);
  }

  Future<void> clearAll({bool deleteMediaFiles = false}) async {
    if (deleteMediaFiles) {
      final rows = await _database.query('raw_media');
      for (final row in rows) {
        final path = row['source_path'] as String?;
        if (path != null && path.isNotEmpty) {
          unawaited(File(path).delete().catchError((_) {}));
        }
      }
    }
    await _database.delete('raw_media');
  }

  RawMediaMetadata _mapMetadata(Map<String, Object?> row) {
    final extrasJson = row['extras'] as String?;
    Map<String, dynamic> extras = <String, dynamic>{};
    if (extrasJson != null && extrasJson.isNotEmpty) {
      final decoded = jsonDecode(extrasJson);
      if (decoded is Map<String, dynamic>) {
        extras = decoded;
      }
    }
    final recognizedJson = row['recognized_transactions_json'] as String?;
    var recognized = <ParsedTransaction>[];
    if (recognizedJson != null && recognizedJson.isNotEmpty) {
      final decoded = jsonDecode(recognizedJson);
      if (decoded is List) {
        recognized = decoded
            .whereType<Map<String, dynamic>>()
            .map(ParsedTransaction.fromJson)
            .toList();
      }
    }
    final capturedAtUtc = DateTime.fromMillisecondsSinceEpoch(
      row['captured_at'] as int,
      isUtc: true,
    );
    final offsetMinutes = row['time_zone_offset_minutes'] as int? ?? 0;
    return RawMediaMetadata(
      id: row['id'] as String,
      type: RawMediaType.values.firstWhere(
        (value) => value.name == row['type'],
        orElse: () => RawMediaType.screenshot,
      ),
      sourcePath: row['source_path'] as String? ?? '',
      capturedAt: capturedAtUtc.toLocal(),
      perceptualHash: row['perceptual_hash'] as String? ?? '',
      displayName: row['display_name'] as String?,
      duration: row['duration_ms'] == null
          ? null
          : Duration(milliseconds: row['duration_ms'] as int),
      frameSampleCount: row['frame_sample_count'] as int? ?? 0,
      extras: extras,
      recognizedTransactions: recognized,
      timeZoneOffsetMinutes: offsetMinutes,
    );
  }
}
