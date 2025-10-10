import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../models/transaction.dart';
import 'raw_media_type.dart';

class TextRecognitionService {
  TextRecognitionService({TextRecognizer? recognizer})
      : _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;
  final RegExp _typeRegex = RegExp(r'\b(Earned|Used|Expired)\b', caseSensitive: false);
  final RegExp _dateRegex = RegExp(
      r'\b(20\d{2})-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\b');
  final RegExp _pointsRegex = RegExp(r'\b-?\d{1,6}\b');

  Future<List<ParsedTransaction>> processImageBytes(
    Uint8List bytes, {
    required RawMediaType mediaType,
    required String sourceId,
  }) async {
    final file = await _writeTempFile(bytes);
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final recognized = await _recognizer.processImage(inputImage);
      return _extractTransactions(
        recognized,
        mediaType: mediaType,
        sourceId: sourceId,
      );
    } finally {
      unawaited(File(file.path).delete().catchError((_) {}));
    }
  }

  Future<List<ParsedTransaction>> processFrames(
    List<Uint8List> frames, {
    required RawMediaType mediaType,
    required String sourceId,
  }) async {
    final results = <String, ParsedTransaction>{};
    for (final frame in frames) {
      final rows = await processImageBytes(
        frame,
        mediaType: mediaType,
        sourceId: sourceId,
      );
      for (final row in rows) {
        final existing = results[row.uniqueHash];
        if (existing == null || row.minConfidence > existing.minConfidence) {
          results[row.uniqueHash] = row;
        }
      }
    }
    return results.values.toList();
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }

  Future<File> _writeTempFile(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final filename =
        'frame_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}.jpg';
    final file = File('${directory.path}/$filename');
    return file.writeAsBytes(bytes, flush: true);
  }

  List<ParsedTransaction> _extractTransactions(
    RecognizedText recognizedText, {
    required RawMediaType mediaType,
    required String sourceId,
  }) {
    final rows = <String, ParsedTransaction>{};
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final parsed = _parseLine(
          line,
          sourceId: sourceId,
          mediaType: mediaType,
        );
        if (parsed == null) {
          continue;
        }
        final existing = rows[parsed.uniqueHash];
        if (existing == null || parsed.minConfidence > existing.minConfidence) {
          rows[parsed.uniqueHash] = parsed;
        }
      }
    }
    return rows.values.toList();
  }

  ParsedTransaction? _parseLine(
    TextLine line, {
    required String sourceId,
    required RawMediaType mediaType,
  }) {
    final text = line.text;
    final typeMatch = _typeRegex.firstMatch(text);
    final dateMatch = _dateRegex.firstMatch(text);
    final pointsMatch = _pointsRegex.firstMatch(text);
    if (typeMatch == null || dateMatch == null || pointsMatch == null) {
      return null;
    }

    final type = TransactionTypeLabel.fromString(typeMatch.group(0)!);
    final rawPoints = int.tryParse(pointsMatch.group(0)!);
    if (rawPoints == null) {
      return null;
    }

    final parsedDate = DateTime.tryParse(dateMatch.group(0)!);
    if (parsedDate == null) {
      return null;
    }

    final normalizedPoints = _normalizePoints(type, rawPoints);
    final typeConfidence = _confidenceForToken(line, typeMatch.group(0)!);
    final dateConfidence = _confidenceForToken(line, dateMatch.group(0)!);
    final pointsConfidence = _confidenceForToken(line, pointsMatch.group(0)!);

    final hash = transactionHash(parsedDate, type, normalizedPoints);
    return ParsedTransaction(
      uniqueHash: hash,
      date: parsedDate,
      type: type,
      points: normalizedPoints,
      sourceId: sourceId,
      sourceType: mediaType,
      rawText: text,
      typeConfidence: typeConfidence,
      dateConfidence: dateConfidence,
      pointsConfidence: pointsConfidence,
    );
  }

  double _confidenceForToken(TextLine line, String rawToken) {
    final token = _normalizeToken(rawToken);
    double? best;
    for (final element in line.elements) {
      final elementToken = _normalizeToken(element.text);
      if (elementToken == token) {
        final confidence = element.confidence ?? (line.confidence ?? 0);
        if (best == null || confidence > best) {
          best = confidence;
        }
      }
    }
    return best ?? (line.confidence ?? 0);
  }

  String _normalizeToken(String value) {
    return value.replaceAll(RegExp(r'[^0-9A-Za-z-]'), '').toLowerCase();
  }

  int _normalizePoints(TransactionType type, int value) {
    final absValue = value.abs();
    return type == TransactionType.used ? -absValue : absValue;
  }

}
