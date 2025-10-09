import 'models.dart';
import 'ledger.dart';
import 'ocr.dart';

final RegExp _typeRe = RegExp(r"\b(Earned|Used|Expired)\b");
final RegExp _dateRe = RegExp(
  r"\b(20\d{2})-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\b",
);
final RegExp _pointsRe = RegExp(r"\b-?\d{1,6}\b");

List<TransactionRecord> parseOcrText(String text) {
  final lines = text.split(RegExp(r"[\r\n]+"));
  final records = <TransactionRecord>[];
  for (final line in lines) {
    final record = _parseLine(line, false);
    if (record != null) {
      records.add(record);
    }
  }
  return records;
}

List<TransactionRecord> parseOcrResults(List<OcrResult> ocrResults) {
  final records = <TransactionRecord>[];
  for (final ocrResult in ocrResults) {
    final record = _parseLine(ocrResult.text, ocrResult.needsReview);
    if (record != null) {
      records.add(record);
    }
  }
  return records;
}

TransactionRecord? _parseLine(String line, bool lowConfidence) {
  final typeMatch = _typeRe.firstMatch(line);
  final dateMatch = _dateRe.firstMatch(line);
  final pointsMatch = _pointsRe.firstMatch(line);

  if (typeMatch == null || dateMatch == null || pointsMatch == null) {
    return null;
  }

  final typeStr = typeMatch.group(0)!;
  final dateStr = dateMatch.group(0)!;
  final pointsStr = pointsMatch.group(0)!;

  final type = _parseTransactionType(typeStr);
  final date = DateTime.parse(dateStr);
  final points = int.parse(pointsStr).abs(); // Always store as positive

  // Flag for review if low confidence or if parsing seems suspicious
  final needsReview = lowConfidence || _shouldFlagForReview(line, type, points);

  return TransactionRecord(
    date: date,
    type: type,
    points: points,
    needsReview: needsReview,
  );
}

TransactionType _parseTransactionType(String typeStr) {
  switch (typeStr) {
    case 'Earned':
      return TransactionType.earned;
    case 'Used':
      return TransactionType.used;
    case 'Expired':
      return TransactionType.expired;
    default:
      return TransactionType.earned; // fallback
  }
}

bool _shouldFlagForReview(String line, TransactionType type, int points) {
  // Flag for review if points seem unusually high or format is suspicious
  if (points > 50000) return true; // Unusually high points
  if (points == 0) return true; // Zero points is suspicious

  // Additional checks based on McDonald's typical patterns
  // You can enhance this based on real data patterns
  return false;
}
