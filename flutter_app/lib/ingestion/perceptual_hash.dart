import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class PerceptualHash {
  const PerceptualHash({
    this.hashSize = 8,
    this.duplicateThreshold = 8,
  });

  final int hashSize;
  final int duplicateThreshold;

  String hash(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Unable to decode image data');
    }
    final resized = img.copyResize(decoded, width: hashSize, height: hashSize);
    final grayscale = img.grayscale(resized);
    final pixels = grayscale.getBytes(order: img.ChannelOrder.rgb);
    final values = <int>[];
    for (var i = 0; i < pixels.length; i += 3) {
      values.add(pixels[i]);
    }
    if (values.isEmpty) {
      return '';
    }
    final average = values.reduce((a, b) => a + b) / values.length;
    final buffer = StringBuffer();
    for (final value in values) {
      buffer.write(value > average ? '1' : '0');
    }
    return _bitsToHex(buffer.toString());
  }

  bool areNearDuplicates(String a, String b) {
    return hammingDistance(a, b) <= duplicateThreshold;
  }

  int hammingDistance(String a, String b) {
    final maxLength = max(a.length, b.length);
    final aBits = _hexToBits(a).padRight(maxLength, '0');
    final bBits = _hexToBits(b).padRight(maxLength, '0');
    var distance = 0;
    for (var i = 0; i < maxLength; i++) {
      if (aBits[i] != bBits[i]) {
        distance++;
      }
    }
    return distance;
  }

  String _bitsToHex(String bits) {
    final buffer = StringBuffer();
    for (var i = 0; i < bits.length; i += 4) {
      final chunk = bits.substring(i, i + 4);
      final value = int.parse(chunk, radix: 2);
      buffer.write(value.toRadixString(16));
    }
    return buffer.toString();
  }

  String _hexToBits(String hex) {
    final buffer = StringBuffer();
    for (final char in hex.split('')) {
      final value = int.parse(char, radix: 16);
      buffer.write(value.toRadixString(2).padLeft(4, '0'));
    }
    return buffer.toString();
  }
}
