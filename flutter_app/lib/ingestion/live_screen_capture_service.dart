import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';

import 'adaptive_frame_extractor.dart';
import 'perceptual_hash.dart';

class LiveScreenCaptureService {
  LiveScreenCaptureService({
    required AdaptiveFrameExtractor frameExtractor,
    required PerceptualHash hasher,
  })  : _frameExtractor = frameExtractor,
        _hasher = hasher;

  final AdaptiveFrameExtractor _frameExtractor;
  final PerceptualHash _hasher;

  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final accessibilityStatus = await Permission.accessibilityService.request();
    if (!accessibilityStatus.isGranted) {
      return false;
    }
    final overlayStatus = await Permission.systemAlertWindow.request();
    return overlayStatus.isGranted || overlayStatus.isLimited;
  }

  Stream<Uint8List> startCapture(Stream<Uint8List> rawFrames) {
    return _frameExtractor.extractDistinctFrames(
      rawFrames,
      hasher: _hasher,
    );
  }
}
