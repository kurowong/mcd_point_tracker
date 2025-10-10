import '../ingestion/raw_media_type.dart';
import 'transaction.dart';

class ReviewEntry {
  ReviewEntry({required this.id, required this.original})
      : editedDate = original.date,
        editedType = original.type,
        editedPoints = original.points.abs(),
        editedTimeZoneOffsetMinutes = original.timeZoneOffsetMinutes;

  final String id;
  final ParsedTransaction original;
  DateTime editedDate;
  TransactionType editedType;
  int editedPoints;
  int editedTimeZoneOffsetMinutes;

  double get minConfidence => original.minConfidence;
  bool get needsReview => original.needsReview;
  String get rawText => original.rawText;
  String get sourceId => original.sourceId;
  RawMediaType get sourceType => original.sourceType;

  int get effectivePoints {
    final value = editedPoints.abs();
    return editedType == TransactionType.used ? -value : value;
  }

  String get editedHash =>
      transactionHash(editedDate, editedType, effectivePoints);

  ReviewEntry copy() {
    return ReviewEntry(id: id, original: original)
      ..editedDate = editedDate
      ..editedType = editedType
      ..editedPoints = editedPoints
      ..editedTimeZoneOffsetMinutes = editedTimeZoneOffsetMinutes;
  }

  ReviewEntry copyWith({
    DateTime? editedDate,
    TransactionType? editedType,
    int? editedPoints,
    int? editedTimeZoneOffsetMinutes,
  }) {
    final clone = copy();
    if (editedDate != null) {
      clone.editedDate = editedDate;
    }
    if (editedType != null) {
      clone.editedType = editedType;
    }
    if (editedPoints != null) {
      clone.editedPoints = editedPoints;
    }
    if (editedTimeZoneOffsetMinutes != null) {
      clone.editedTimeZoneOffsetMinutes = editedTimeZoneOffsetMinutes;
    }
    return clone;
  }
}
