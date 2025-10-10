import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../ingestion/raw_media_type.dart';

enum TransactionType { earned, used, expired }

extension TransactionTypeLabel on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.earned:
        return 'Earned';
      case TransactionType.used:
        return 'Used';
      case TransactionType.expired:
        return 'Expired';
    }
  }

  static TransactionType fromString(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'earned') {
      return TransactionType.earned;
    }
    if (normalized == 'used') {
      return TransactionType.used;
    }
    if (normalized == 'expired') {
      return TransactionType.expired;
    }
    throw ArgumentError.value(value, 'value', 'Unsupported transaction type');
  }
}

class ParsedTransaction {
  ParsedTransaction({
    required this.uniqueHash,
    required this.date,
    required this.type,
    required this.points,
    required this.sourceId,
    required this.sourceType,
    required this.rawText,
    required this.typeConfidence,
    required this.dateConfidence,
    required this.pointsConfidence,
  });

  final String uniqueHash;
  final DateTime date;
  final TransactionType type;
  final int points;
  final String sourceId;
  final RawMediaType sourceType;
  final String rawText;
  final double typeConfidence;
  final double dateConfidence;
  final double pointsConfidence;

  double get minConfidence =>
      [typeConfidence, dateConfidence, pointsConfidence]
          .reduce(min);

  bool get needsReview => minConfidence < 0.99;

  ParsedTransaction copyWith({
    String? uniqueHash,
    DateTime? date,
    TransactionType? type,
    int? points,
    String? sourceId,
    RawMediaType? sourceType,
    String? rawText,
    double? typeConfidence,
    double? dateConfidence,
    double? pointsConfidence,
  }) {
    return ParsedTransaction(
      uniqueHash: uniqueHash ?? this.uniqueHash,
      date: date ?? this.date,
      type: type ?? this.type,
      points: points ?? this.points,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      rawText: rawText ?? this.rawText,
      typeConfidence: typeConfidence ?? this.typeConfidence,
      dateConfidence: dateConfidence ?? this.dateConfidence,
      pointsConfidence: pointsConfidence ?? this.pointsConfidence,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uniqueHash': uniqueHash,
      'date': date.toIso8601String(),
      'type': type.name,
      'points': points,
      'sourceId': sourceId,
      'sourceType': sourceType.name,
      'rawText': rawText,
      'typeConfidence': typeConfidence,
      'dateConfidence': dateConfidence,
      'pointsConfidence': pointsConfidence,
    };
  }

  static ParsedTransaction fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      uniqueHash: json['uniqueHash'] as String,
      date: DateTime.parse(json['date'] as String),
      type: TransactionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => TransactionType.earned,
      ),
      points: json['points'] as int,
      sourceId: json['sourceId'] as String? ?? '',
      sourceType: RawMediaType.values.firstWhere(
        (value) => value.name == json['sourceType'],
        orElse: () => RawMediaType.screenshot,
      ),
      rawText: json['rawText'] as String? ?? '',
      typeConfidence: (json['typeConfidence'] as num?)?.toDouble() ?? 0,
      dateConfidence: (json['dateConfidence'] as num?)?.toDouble() ?? 0,
      pointsConfidence: (json['pointsConfidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ConfirmedTransaction {
  ConfirmedTransaction({
    required this.uniqueHash,
    required this.date,
    required this.type,
    required this.points,
    required this.sourceId,
    required this.sourceType,
    required this.approvedAt,
    required this.rawText,
  });

  final String uniqueHash;
  final DateTime date;
  final TransactionType type;
  final int points;
  final String sourceId;
  final RawMediaType sourceType;
  final DateTime approvedAt;
  final String rawText;
}

String transactionKey(DateTime date, TransactionType type, int points) {
  final isoDate = date.toIso8601String().split('T').first;
  return '$isoDate|${type.name}|$points';
}

String transactionHash(DateTime date, TransactionType type, int points) {
  final key = transactionKey(date, type, points);
  return sha1.convert(utf8.encode(key)).toString();
}
