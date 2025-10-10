import 'dart:async';
import 'dart:typed_data';

import 'perceptual_hash.dart';

class AdaptiveFrameExtractor {
  AdaptiveFrameExtractor({
    this.minFps = 2,
    this.maxFps = 5,
    this.lowVarianceThreshold = 6,
    this.highVarianceThreshold = 18,
  });

  final double minFps;
  final double maxFps;
  final int lowVarianceThreshold;
  final int highVarianceThreshold;

  Stream<Uint8List> extractDistinctFrames(
    Stream<Uint8List> rawFrames, {
    required PerceptualHash hasher,
  }) async* {
    var currentFps = minFps;
    var framesUntilNextSample = _framesForFps(currentFps);
    String? lastHash;

    await for (final frame in rawFrames) {
      if (framesUntilNextSample > 0) {
        framesUntilNextSample -= 1;
      }

      final hash = hasher.hash(frame);
      final isDuplicate =
          lastHash != null && hasher.areNearDuplicates(lastHash!, hash);

      if (isDuplicate && framesUntilNextSample > 0) {
        currentFps = (currentFps - 0.5).clamp(minFps, maxFps);
        framesUntilNextSample = _framesForFps(currentFps);
        continue;
      }

      if (framesUntilNextSample > 0) {
        continue;
      }

      yield frame;
      final variance = lastHash == null
          ? highVarianceThreshold
          : hasher.hammingDistance(lastHash!, hash);
      lastHash = hash;

      if (variance >= highVarianceThreshold) {
        currentFps = (currentFps + 1).clamp(minFps, maxFps);
      } else if (variance <= lowVarianceThreshold) {
        currentFps = (currentFps - 0.5).clamp(minFps, maxFps);
      }

      framesUntilNextSample = _framesForFps(currentFps);
    }
  }

  Future<List<Uint8List>> collectDistinctFrames(
    Stream<Uint8List> rawFrames, {
    required PerceptualHash hasher,
  }) async {
    final samples = <Uint8List>[];
    await for (final frame in extractDistinctFrames(rawFrames, hasher: hasher)) {
      samples.add(frame);
    }
    return samples;
  }

  int _framesForFps(double fps) {
    // Assume a 30fps source by default and clamp the sampling stride.
    final stride = (30 / fps).round();
    return stride.clamp(1, 15);
  }
}
