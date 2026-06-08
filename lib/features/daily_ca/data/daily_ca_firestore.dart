import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore layout (matches Python pipeline):
///
///     daily_mcqs / {YYYY} / {MM} / {DD}
///
/// - `daily_mcqs` — root collection
/// - `{YYYY}`     — document id (e.g. `2026`)
/// - `{MM}`       — subcollection id, zero-padded (e.g. `06`)
/// - `{DD}`       — document id, zero-padded (e.g. `08`)
abstract final class DailyCaFirestore {
  DailyCaFirestore._();

  static const collectionName = 'daily_mcqs';

  /// Parses `YYYY-MM-DD` into zero-padded `(year, month, day)` path segments.
  static ({String year, String month, String day}) pathSegments(String isoDate) {
    final match = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(isoDate.trim());
    if (match == null) {
      throw ArgumentError('Invalid ISO date (expected YYYY-MM-DD): $isoDate');
    }
    final year = match.group(1)!;
    final month = match.group(2)!.padLeft(2, '0');
    final day = match.group(3)!.padLeft(2, '0');
    return (year: year, month: month, day: day);
  }

  /// Human-readable path, e.g. `daily_mcqs/2026/06/08`.
  static String pathForDate(String isoDate) {
    final s = pathSegments(isoDate);
    return '$collectionName/${s.year}/${s.month}/${s.day}';
  }

  /// Document reference: `daily_mcqs/{year}/{month}/{day}`.
  static DocumentReference<Map<String, dynamic>> dayDoc(String isoDate) {
    final s = pathSegments(isoDate);
    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(s.year)
        .collection(s.month)
        .doc(s.day);
  }
}
