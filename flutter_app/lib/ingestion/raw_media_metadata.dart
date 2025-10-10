import 'dart:convert';

import '../models/transaction.dart';
import 'raw_media_type.dart';

export 'raw_media_type.dart';

class RawMediaMetadata {
  RawMediaMetadata({
    required this.id,
    required this.type,
    required this.sourcePath,
    required this.capturedAt,
    required this.perceptualHash,
    this.displayName,
    this.duration,
    this.frameSampleCount = 0,
    Map<String, dynamic>? extras,
    List<ParsedTransaction>? recognizedTransactions,
  })  : extras = extras ?? <String, dynamic>{},
        recognizedTransactions =
            recognizedTransactions ?? <ParsedTransaction>[];

  final String id;
  final RawMediaType type;
  final String sourcePath;
  final DateTime capturedAt;
  final String perceptualHash;
  final String? displayName;
  final Duration? duration;
  final int frameSampleCount;
  final Map<String, dynamic> extras;
  final List<ParsedTransaction> recognizedTransactions;

  String get prettyLabel => displayName ?? sourcePath;

  RawMediaMetadata copyWith({
    String? id,
    RawMediaType? type,
    String? sourcePath,
    DateTime? capturedAt,
    String? perceptualHash,
    String? displayName,
    Duration? duration,
    int? frameSampleCount,
    Map<String, dynamic>? extras,
    List<ParsedTransaction>? recognizedTransactions,
  }) {
    return RawMediaMetadata(
      id: id ?? this.id,
      type: type ?? this.type,
      sourcePath: sourcePath ?? this.sourcePath,
      capturedAt: capturedAt ?? this.capturedAt,
      perceptualHash: perceptualHash ?? this.perceptualHash,
      displayName: displayName ?? this.displayName,
      duration: duration ?? this.duration,
      frameSampleCount: frameSampleCount ?? this.frameSampleCount,
      extras: extras ?? Map<String, dynamic>.from(this.extras),
      recognizedTransactions:
          recognizedTransactions ?? List<ParsedTransaction>.from(this.recognizedTransactions),
    );
  }

  bool isExpired(Duration retention) {
    return DateTime.now().isAfter(capturedAt.add(retention));
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'sourcePath': sourcePath,
      'capturedAt': capturedAt.toIso8601String(),
      'perceptualHash': perceptualHash,
      'displayName': displayName,
      'duration': duration?.inMilliseconds,
      'frameSampleCount': frameSampleCount,
      'extras': extras,
      'recognizedTransactions':
          recognizedTransactions.map((entry) => entry.toJson()).toList(),
    };
  }

  static RawMediaMetadata fromJson(Map<String, dynamic> json) {
    return RawMediaMetadata(
      id: json['id'] as String,
      type: RawMediaType.values.firstWhere(
        (element) => element.name == json['type'],
        orElse: () => RawMediaType.screenshot,
      ),
      sourcePath: json['sourcePath'] as String? ?? '',
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      perceptualHash: json['perceptualHash'] as String? ?? '',
      displayName: json['displayName'] as String?,
      duration: json['duration'] == null
          ? null
          : Duration(milliseconds: json['duration'] as int),
      frameSampleCount: json['frameSampleCount'] as int? ?? 0,
      extras: (json['extras'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value),
          ) ??
          <String, dynamic>{},
      recognizedTransactions: (json['recognizedTransactions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ParsedTransaction.fromJson)
              .toList() ??
          <ParsedTransaction>[],
    );
  }

  static String encodeList(List<RawMediaMetadata> entries) {
    final list = entries.map((entry) => entry.toJson()).toList();
    return jsonEncode(list);
  }

  static List<RawMediaMetadata> decodeList(String? value) {
    if (value == null || value.isEmpty) {
      return <RawMediaMetadata>[];
    }
    final dynamic decoded = jsonDecode(value);
    if (decoded is! List<dynamic>) {
      return <RawMediaMetadata>[];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(RawMediaMetadata.fromJson)
        .toList();
  }
}
