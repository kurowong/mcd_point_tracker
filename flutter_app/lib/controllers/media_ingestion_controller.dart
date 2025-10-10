import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ingestion/adaptive_frame_extractor.dart';
import '../ingestion/gallery_video_import_service.dart';
import '../ingestion/live_screen_capture_service.dart';
import '../ingestion/media_repository.dart';
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
    required MediaRepository repository,
    required TextRecognitionService textRecognition,
    required TransactionReviewController reviewController,
  })  : _repository = repository,
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

  final MediaRepository _repository;
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
    final storedAssets = await _repository.loadMetadata();
    _assets
      ..clear()
      ..addAll(storedAssets);
    _retentionDays = await _repository.loadRetentionDays();
    _ingestRecognizedTransactions(storedAssets);
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
    _ingestRecognizedTransactions(additions);
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

  void _ingestRecognizedTransactions(List<RawMediaMetadata> metadata) {
    final transactions = <ParsedTransaction>[];
    for (final item in metadata) {
      transactions.addAll(item.recognizedTransactions);
    }
    if (transactions.isNotEmpty) {
      _reviewController.ingestRecognizedTransactions(transactions);
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
    _ingestRecognizedTransactions([metadata]);
    notifyListeners();
  }
}
