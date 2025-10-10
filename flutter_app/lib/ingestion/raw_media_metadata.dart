import 'dart:convert';

enum RawMediaType { screenshot, video, liveCapture }

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
  }) : extras = extras ?? <String, dynamic>{};

  final String id;
  final RawMediaType type;
  final String sourcePath;
  final DateTime capturedAt;
  final String perceptualHash;
  final String? displayName;
  final Duration? duration;
  final int frameSampleCount;
  final Map<String, dynamic> extras;

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
