import 'package:shared_preferences/shared_preferences.dart';

import 'raw_media_metadata.dart';

class MediaRepository {
  MediaRepository._(this._preferences);

  static const String _metadataKey = 'raw_media_metadata';
  static const String _retentionKey = 'raw_media_retention_days';

  final SharedPreferences _preferences;

  static Future<MediaRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MediaRepository._(prefs);
  }

  Future<List<RawMediaMetadata>> loadMetadata() async {
    final serialized = _preferences.getString(_metadataKey);
    return RawMediaMetadata.decodeList(serialized);
  }

  Future<void> saveMetadata(List<RawMediaMetadata> metadata) async {
    final encoded = RawMediaMetadata.encodeList(metadata);
    await _preferences.setString(_metadataKey, encoded);
  }

  Future<int> loadRetentionDays({int fallback = 7}) async {
    return _preferences.getInt(_retentionKey) ?? fallback;
  }

  Future<void> saveRetentionDays(int days) async {
    await _preferences.setInt(_retentionKey, days);
  }

  Future<int> cleanupExpired(Duration retention) async {
    final existing = await loadMetadata();
    final threshold = DateTime.now().subtract(retention);
    final retained = existing
        .where((entry) => entry.capturedAt.isAfter(threshold))
        .toList();
    await saveMetadata(retained);
    return existing.length - retained.length;
  }

  Future<void> appendMetadata(List<RawMediaMetadata> additions) async {
    if (additions.isEmpty) {
      return;
    }
    final existing = await loadMetadata();
    existing.addAll(additions);
    existing.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    await saveMetadata(existing);
  }
}
