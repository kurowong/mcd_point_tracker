import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:mcd_point_tracker/ingestion/perceptual_hash.dart';

void main() {
  group('PerceptualHash', () {
    late PerceptualHash hasher;

    setUp(() {
      hasher = const PerceptualHash();
    });

    test('produces identical hash for identical images', () {
      final image = _buildPatternImage();
      final bytes = Uint8List.fromList(img.encodePng(image));
      final otherBytes = Uint8List.fromList(bytes);

      final hashA = hasher.hash(bytes);
      final hashB = hasher.hash(otherBytes);

      expect(hashA, equals(hashB));
      expect(hashA.length, greaterThan(0));
    });

    test('detects near duplicates under small luminance changes', () {
      final base = _buildPatternImage();
      final brighter = _buildPatternImage(adjustment: 12);

      final baseHash = hasher.hash(Uint8List.fromList(img.encodePng(base)));
      final brighterHash =
          hasher.hash(Uint8List.fromList(img.encodePng(brighter)));

      expect(baseHash, isNotEmpty);
      expect(brighterHash, isNotEmpty);
      expect(hasher.areNearDuplicates(baseHash, brighterHash), isTrue);
      expect(hasher.hammingDistance(baseHash, brighterHash), lessThan(16));
    });

    test('distinguishes clearly different images', () {
      final base = _buildPatternImage();
      final inverted = _buildPatternImage(invert: true);

      final baseHash = hasher.hash(Uint8List.fromList(img.encodePng(base)));
      final invertedHash =
          hasher.hash(Uint8List.fromList(img.encodePng(inverted)));

      expect(hasher.areNearDuplicates(baseHash, invertedHash), isFalse);
      expect(
        hasher.hammingDistance(baseHash, invertedHash),
        greaterThan(hasher.duplicateThreshold),
      );
    });
  });
}

img.Image _buildPatternImage({int adjustment = 0, bool invert = false}) {
  const size = 64;
  final image = img.Image(width: size, height: size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final inSquare = x >= 16 && x < 48 && y >= 16 && y < 48;
      final baseValue = inSquare ? 220 : 40;
      var value = baseValue + adjustment;
      if (invert) {
        value = 255 - value;
      }
      final channel = value.clamp(0, 255).toInt();
      image.setPixelRgb(x, y, channel, channel, channel);
    }
  }
  return image;
}
