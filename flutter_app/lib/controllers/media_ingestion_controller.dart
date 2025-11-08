import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/raw_media_repository.dart';
import '../data/settings_repository.dart';
import '../ingestion/adaptive_frame_extractor.dart';
import '../ingestion/gallery_video_import_service.dart';
import '../ingestion/live_screen_capture_service.dart';
import '../ingestion/perceptual_hash.dart';
import '../ingestion/raw_media_metadata.dart';
import '../ingestion/raw_media_type.dart';
import '../ingestion/screenshot_import_service.dart';
import '../ingestion/text_recognition_service.dart';
import '../models/transaction.dart';
import 'transaction_review_controller.dart';

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
  MediaIngestionController({
    required RawMediaRepository mediaRepository,
    required SettingsRepository settingsRepository,
    required TextRecognitionService textRecognition,
    required TransactionReviewController reviewController,
  })  : _mediaRepository = mediaRepository,
        _settingsRepository = settingsRepository,
        _hasher = const PerceptualHash(),
        _textRecognition = textRecognition,
        _reviewController = reviewController {
    final extractor = AdaptiveFrameExtractor();
    _screenshotService = ScreenshotImportService(
      hasher: _hasher,
      textRecognition: _textRecognition,
    );
    _videoService = GalleryVideoImportService(
      frameExtractor: extractor,
      hasher: _hasher,
      textRecognition: _textRecognition,
    );
    _liveService = LiveScreenCaptureService(
      frameExtractor: extractor,
      hasher: _hasher,
    );
  }

  final RawMediaRepository _mediaRepository;
  final SettingsRepository _settingsRepository;
  final PerceptualHash _hasher;
  final TextRecognitionService _textRecognition;
  final TransactionReviewController _reviewController;
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
    final storedAssets = await _mediaRepository.loadMetadata();
    _assets
      ..clear()
      ..addAll(storedAssets);
    _retentionDays = await _settingsRepository.loadRetentionDays();
    await _ingestRecognizedTransactions(storedAssets);
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
    await _mediaRepository.appendMetadata(additions);
    await _ingestRecognizedTransactions(additions);
    notifyListeners();
  }

  Future<void> setRetentionDays(int days) async {
    if (days == _retentionDays) {
      return;
    }
    _retentionDays = days;
    await _settingsRepository.saveRetentionDays(days);
    notifyListeners();
  }

  Future<int> cleanupExpiredAssets() async {
    final removed = await _mediaRepository
        .cleanupExpired(Duration(days: _retentionDays));
    if (removed > 0) {
      final retained = await _mediaRepository.loadMetadata();
      _assets
        ..clear()
        ..addAll(retained);
      notifyListeners();
    }
    return removed;
  }

  Future<void> resetAll({bool deleteMediaFiles = false}) async {
    await _mediaRepository.clearAll(deleteMediaFiles: deleteMediaFiles);
    _assets.clear();
    _retentionDays = await _settingsRepository.loadRetentionDays();
    notifyListeners();
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
        unawaited(_handleLiveFrame(frame));
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

  Future<void> _ingestRecognizedTransactions(
      List<RawMediaMetadata> metadata) async {
    final transactions = <ParsedTransaction>[];
    for (final item in metadata) {
      transactions.addAll(item.recognizedTransactions);
    }
    if (transactions.isNotEmpty) {
      await _reviewController.ingestRecognizedTransactions(transactions);
    }
  }

  Future<void> _handleLiveFrame(Uint8List frame) async {
    final id = 'live-${DateTime.now().millisecondsSinceEpoch}';
    final hash = _hasher.hash(frame);
    List<ParsedTransaction> parsed = const [];
    try {
      parsed = await _textRecognition.processFrames(
        [frame],
        mediaType: RawMediaType.liveCapture,
        sourceId: id,
      );
    } catch (_) {
      parsed = const [];
    }
    final metadata = RawMediaMetadata(
      id: id,
      type: RawMediaType.liveCapture,
      sourcePath: 'live-capture',
      capturedAt: DateTime.now(),
      perceptualHash: hash,
      frameSampleCount: 1,
      recognizedTransactions: parsed,
    );
    _assets.add(metadata);
    _assets.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    await _ingestRecognizedTransactions([metadata]);
    notifyListeners();
  }
}
