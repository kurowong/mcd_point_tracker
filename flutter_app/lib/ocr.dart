import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String text;
  final double confidence;
  final bool needsReview;

  OcrResult(this.text, this.confidence, this.needsReview);
}

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  static const double confidenceThreshold = 0.99;

  Future<String> extractTextFromImage(File imageFile) async {
    final input = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  Future<List<OcrResult>> extractTextWithConfidence(File imageFile) async {
    final input = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(input);

    final ocrResults = <OcrResult>[];

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text;
        // Google ML Kit doesn't provide confidence per line, so we use element-level confidence
        double lineConfidence = 1.0;
        for (final element in line.elements) {
          final elementConfidence = element.confidence ?? 1.0;
          lineConfidence = lineConfidence * elementConfidence;
        }

        final needsReview = lineConfidence < confidenceThreshold;
        ocrResults.add(OcrResult(text, lineConfidence, needsReview));
      }
    }

    return ocrResults;
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
