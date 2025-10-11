import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class PerceptualHash {
  const PerceptualHash({
    this.hashSize = 8,
    this.duplicateThreshold = 8,
  });

  /// The edge length, in pixels, of the low-frequency DCT sample region.
  final int hashSize;

  /// Maximum Hamming distance that will still be considered a near duplicate.
  final int duplicateThreshold;

  /// Number of pixels to sample when computing the DCT. This roughly follows
  /// the reference pHash implementation which resizes to 32x32 before taking
  /// an 8x8 DCT.
  static const int _preprocessSize = 32;
  static const double _sqrt2 = 1.4142135623730951;

  String hash(Uint8List bytes) {
    if (hashSize > _preprocessSize) {
      throw ArgumentError(
        'hashSize ($hashSize) must be <= $_preprocessSize for DCT sampling.',
      );
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Unable to decode image data');
    }

    final resized = img.copyResize(
      decoded,
      width: _preprocessSize,
      height: _preprocessSize,
      interpolation: img.Interpolation.cubic,
    );

    final grayscale = img.grayscale(resized);
    final pixels = grayscale.getBytes(order: img.ChannelOrder.rgb);
    if (pixels.isEmpty) {
      return '';
    }

    final luminance = List<double>.generate(
      _preprocessSize * _preprocessSize,
      (index) => pixels[index * 3].toDouble(),
      growable: false,
    );

    final dctValues = _computeTopLeftDct(luminance);
    if (dctValues.isEmpty) {
      return '';
    }

    final coefficients = <double>[];
    final lowFrequencySamples = <double>[];
    for (var y = 0; y < hashSize; y++) {
      for (var x = 0; x < hashSize; x++) {
        final value = dctValues[y * hashSize + x];
        coefficients.add(value);
        if (x == 0 && y == 0) {
          continue;
        }
        lowFrequencySamples.add(value);
      }
    }

    final median = _median(lowFrequencySamples);
    final buffer = StringBuffer();
    for (final value in coefficients) {
      buffer.write(value > median ? '1' : '0');
    }
    return _bitsToHex(buffer.toString());
  }

  bool areNearDuplicates(String a, String b) {
    return hammingDistance(a, b) <= duplicateThreshold;
  }

  int hammingDistance(String a, String b) {
    final aBits = _hexToBits(a);
    final bBits = _hexToBits(b);
    final bitLength = max(aBits.length, bBits.length);
    final normalizedA = aBits.padRight(bitLength, '0');
    final normalizedB = bBits.padRight(bitLength, '0');
    var distance = 0;
    for (var i = 0; i < bitLength; i++) {
      if (normalizedA[i] != normalizedB[i]) {
        distance++;
      }
    }
    return distance;
  }

  List<double> _computeTopLeftDct(List<double> pixels) {
    final size = _preprocessSize;
    final output = List<double>.filled(hashSize * hashSize, 0);
    for (var v = 0; v < hashSize; v++) {
      for (var u = 0; u < hashSize; u++) {
        var sum = 0.0;
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            final pixel = pixels[y * size + x];
            sum += pixel *
                cos(((2 * x + 1) * u * pi) / (2 * size)) *
                cos(((2 * y + 1) * v * pi) / (2 * size));
          }
        }
        final alphaU = u == 0 ? 1 / _sqrt2 : 1.0;
        final alphaV = v == 0 ? 1 / _sqrt2 : 1.0;
        output[v * hashSize + u] = 0.25 * alphaU * alphaV * sum;
      }
    }
    return output;
  }

  double _median(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  String _bitsToHex(String bits) {
    final buffer = StringBuffer();
    for (var i = 0; i < bits.length; i += 4) {
      final end = min(i + 4, bits.length);
      final chunk = bits.substring(i, end).padRight(4, '0');
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
