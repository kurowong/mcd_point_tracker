import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ingestion/adaptive_frame_extractor.dart';
import '../ingestion/gallery_video_import_service.dart';
import '../ingestion/live_screen_capture_service.dart';
import '../ingestion/media_repository.dart';
import '../ingestion/perceptual_hash.dart';
import '../ingestion/raw_media_metadata.dart';
import '../ingestion/screenshot_import_service.dart';

class IngestionReport {
  IngestionReport({
    required this.unique,
    required this.duplicates,
  });

  final List<RawMediaMetadata> unique;
  final List<RawMediaMetadata> duplicates;

  bool get hasDuplicates => duplicates.isNotEmpty;
  int get total => unique.length + duplicates.length;
}

class MediaIngestionController extends ChangeNotifier {
  MediaIngestionController({required MediaRepository repository})
      : _repository = repository,
        _hasher = const PerceptualHash() {
    final extractor = AdaptiveFrameExtractor();
    _screenshotService = ScreenshotImportService(hasher: _hasher);
    _videoService = GalleryVideoImportService(
      frameExtractor: extractor,
      hasher: _hasher,
    );
    _liveService = LiveScreenCaptureService(
      frameExtractor: extractor,
      hasher: _hasher,
    );
  }

  final MediaRepository _repository;
  final PerceptualHash _hasher;
  late final ScreenshotImportService _screenshotService;
  late final GalleryVideoImportService _videoService;
  late final LiveScreenCaptureService _liveService;

  final List<RawMediaMetadata> _assets = <RawMediaMetadata>[];

  bool _liveCaptureActive = false;
  int _retentionDays = 7;

  List<RawMediaMetadata> get assets => List<RawMediaMetadata>.unmodifiable(_assets);
  int get retentionDays => _retentionDays;
  bool get liveCaptureActive => _liveCaptureActive;

  Future<void> initialize() async {
    final storedAssets = await _repository.loadMetadata();
    _assets
      ..clear()
      ..addAll(storedAssets);
    _retentionDays = await _repository.loadRetentionDays();
    notifyListeners();
  }

  Future<IngestionReport> prepareScreenshotImport() async {
    final freshMetadata = await _screenshotService.fetchMetadata();
    return _partitionDuplicates(freshMetadata);
  }

  Future<IngestionReport> prepareVideoImport() async {
    final freshMetadata = await _videoService.fetchMetadata();
    return _partitionDuplicates(freshMetadata);
  }

  Future<void> finalizeImport(
    IngestionReport report, {
    bool includeDuplicates = false,
  }) async {
    final additions = <RawMediaMetadata>[...report.unique];
    if (includeDuplicates) {
      additions.addAll(report.duplicates);
    }
    if (additions.isEmpty) {
      return;
    }
    _assets.addAll(additions);
    _assets.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    await _repository.appendMetadata(additions);
    notifyListeners();
  }

  Future<void> setRetentionDays(int days) async {
    if (days == _retentionDays) {
      return;
    }
    _retentionDays = days;
    await _repository.saveRetentionDays(days);
    notifyListeners();
  }

  Future<int> cleanupExpiredAssets() async {
    final removed = await _repository
        .cleanupExpired(Duration(days: _retentionDays));
    if (removed > 0) {
      final retained = await _repository.loadMetadata();
      _assets
        ..clear()
        ..addAll(retained);
      notifyListeners();
    }
    return removed;
  }

  Future<bool> ensureLiveCapturePermissions() {
    return _liveService.ensurePermissions();
  }

  Future<void> startLiveCapture(Stream<Uint8List> rawFrames) async {
    final granted = await ensureLiveCapturePermissions();
    if (!granted) {
      throw Exception('Live capture permissions not granted');
    }
    _liveCaptureActive = true;
    notifyListeners();
    unawaited(
      _liveService.startCapture(rawFrames).listen((frame) {
        final hash = _hasher.hash(frame);
        final metadata = RawMediaMetadata(
          id: 'live-${DateTime.now().millisecondsSinceEpoch}',
          type: RawMediaType.liveCapture,
          sourcePath: 'live-capture',
          capturedAt: DateTime.now(),
          perceptualHash: hash,
          frameSampleCount: 1,
        );
        _assets.add(metadata);
        notifyListeners();
      }).asFuture().whenComplete(() {
        _liveCaptureActive = false;
        notifyListeners();
      }),
    );
  }

  void stopLiveCapture() {
    if (!_liveCaptureActive) {
      return;
    }
    _liveCaptureActive = false;
    notifyListeners();
  }

  IngestionReport _partitionDuplicates(List<RawMediaMetadata> fresh) {
    final unique = <RawMediaMetadata>[];
    final duplicates = <RawMediaMetadata>[];
    for (final item in fresh) {
      final match = _assets.firstWhere(
        (existing) =>
            existing.sourcePath == item.sourcePath ||
            _hasher.areNearDuplicates(
              existing.perceptualHash,
              item.perceptualHash,
            ),
        orElse: () => item,
      );
      if (identical(match, item)) {
        unique.add(item);
      } else {
        duplicates.add(item);
      }
    }
    return IngestionReport(unique: unique, duplicates: duplicates);
  }
}
