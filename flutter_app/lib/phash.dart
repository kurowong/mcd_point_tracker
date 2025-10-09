import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

class FrameHash {
  final String hash;
  final int timestamp;

  FrameHash(this.hash, this.timestamp);
}

class FrameDeduplicator {
  final Set<String> _seenHashes = {};
  final List<FrameHash> _frameHistory = [];

  bool isDuplicate(Uint8List imageBytes, int timestamp) {
    final hash = computePerceptualHash(imageBytes);
    _frameHistory.add(FrameHash(hash, timestamp));

    if (_seenHashes.contains(hash)) {
      return true;
    }

    _seenHashes.add(hash);
    return false;
  }

  void reset() {
    _seenHashes.clear();
    _frameHistory.clear();
  }

  int get uniqueFrameCount => _seenHashes.length;
  int get totalFrameCount => _frameHistory.length;
}

String computePerceptualHash(Uint8List imageBytes) {
  try {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      // Fallback to simple hash if image decoding fails
      return md5.convert(imageBytes).toString().substring(0, 16);
    }

    // Resize to 8x8 for simple perceptual hash
    final resized = img.copyResize(image, width: 8, height: 8);

    // Convert to grayscale and compute average
    final pixels = <int>[];
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final gray = ((r + g + b) / 3).round();
        pixels.add(gray);
      }
    }

    final average = pixels.reduce((a, b) => a + b) ~/ pixels.length;

    // Create hash based on pixels above/below average
    var hash = '';
    for (final pixel in pixels) {
      hash += pixel > average ? '1' : '0';
    }

    // Convert binary string to hex
    final hashInt = int.parse(hash, radix: 2);
    return hashInt.toRadixString(16).padLeft(16, '0');
  } catch (e) {
    // Fallback to MD5 if perceptual hashing fails
    return md5.convert(imageBytes).toString().substring(0, 16);
  }
}

// Legacy function for backward compatibility
String phash(List<int> data) {
  return md5.convert(data).toString();
}
