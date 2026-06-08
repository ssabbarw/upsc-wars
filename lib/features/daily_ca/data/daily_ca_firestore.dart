import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore paths for `daily_mcqs/{YYYY}/{MM}/{DD}`.
abstract final class DailyCaFirestore {
  DailyCaFirestore._();

  static const collectionName = 'daily_mcqs';

  static DocumentReference<Map<String, dynamic>> dayDoc(String isoDate) {
    final parts = isoDate.split('-');
    final year = parts[0];
    final month = parts[1];
    final day = parts[2];
    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(year)
        .collection(month)
        .doc(day);
  }
}
