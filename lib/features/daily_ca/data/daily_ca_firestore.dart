import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore layout (matches Python pipeline):
///
///     daily_mcqs / {YYYY} / {MM} / {DD}
///
/// Month and day are always **zero-padded** (`06`, `05`), e.g. `daily_mcqs/2026/06/05`.
abstract final class DailyCaFirestore {
  DailyCaFirestore._();

  static const collectionName = 'daily_mcqs';
  static const draftCollectionName = 'daily_ca_drafts';
  static const generateConfigPath = 'admin_dashboard/daily_ca';

  static DocumentReference<Map<String, dynamic>> generateConfigDoc() {
    return FirebaseFirestore.instance
        .collection('admin_dashboard')
        .doc('daily_ca');
  }

  static Future<void> saveGenerateClock({
    required int hourIst,
    required int minuteIst,
  }) {
    return generateConfigDoc().set(
      {
        'generate_hour_ist': hourIst.clamp(0, 23),
        'generate_minute_ist': minuteIst.clamp(0, 59),
      },
      SetOptions(merge: true),
    );
  }

  /// Parses `YYYY-MM-DD` into zero-padded `(year, month, day)` path segments.
  static ({String year, String month, String day}) pathSegments(String isoDate) {
    final match = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(isoDate.trim());
    if (match == null) {
      throw ArgumentError('Invalid ISO date (expected YYYY-MM-DD): $isoDate');
    }
    return (
      year: match.group(1)!,
      month: match.group(2)!.padLeft(2, '0'),
      day: match.group(3)!.padLeft(2, '0'),
    );
  }

  /// e.g. `daily_mcqs/2026/06/05`
  static String pathForDate(String isoDate) {
    final s = pathSegments(isoDate);
    return '$collectionName/${s.year}/${s.month}/${s.day}';
  }

  /// Document at `daily_mcqs/{year}/{month}/{day}`.
  static DocumentReference<Map<String, dynamic>> dayDoc(String isoDate) {
    final s = pathSegments(isoDate);
    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(s.year)
        .collection(s.month)
        .doc(s.day);
  }

  /// Admin review draft at `daily_ca_drafts/{YYYY-MM-DD}`.
  static DocumentReference<Map<String, dynamic>> draftDoc(String isoDate) {
    return FirebaseFirestore.instance
        .collection(draftCollectionName)
        .doc(isoDate.trim());
  }
}
