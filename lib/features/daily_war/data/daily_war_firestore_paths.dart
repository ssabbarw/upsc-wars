import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore layout for Daily War.
///
///     daily_wars/{YYYY-MM-DD}                    — public meta + topics
///     daily_wars/{dateId}/private/answers          — correct keys (Functions only)
///     daily_wars/{dateId}/submissions/{uid}        — scored attempts (Functions write)
///     daily_wars/{dateId}/meta/leaderboard         — top 100 + histogram
///     daily_war_state/curriculum                   — topic pointers (Functions only)
///     daily_war_profiles/{uid}                     — lifetime badge_counts
abstract final class DailyWarFirestorePaths {
  DailyWarFirestorePaths._();

  static const warsCollection = 'daily_wars';
  static const stateCollection = 'daily_war_state';
  static const profilesCollection = 'daily_war_profiles';
  static const curriculumDocId = 'curriculum';

  static String dateIdFromIst(DateTime istDate) {
    final y = istDate.year.toString().padLeft(4, '0');
    final m = istDate.month.toString().padLeft(2, '0');
    final d = istDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DocumentReference<Map<String, dynamic>> warDoc(String dateId) {
    return FirebaseFirestore.instance.collection(warsCollection).doc(dateId);
  }

  static DocumentReference<Map<String, dynamic>> privateAnswersDoc(
    String dateId,
  ) {
    return warDoc(dateId).collection('private').doc('answers');
  }

  static CollectionReference<Map<String, dynamic>> submissionsCol(
    String dateId,
  ) {
    return warDoc(dateId).collection('submissions');
  }

  static DocumentReference<Map<String, dynamic>> submissionDoc(
    String dateId,
    String uid,
  ) {
    return submissionsCol(dateId).doc(uid);
  }

  static DocumentReference<Map<String, dynamic>> leaderboardDoc(String dateId) {
    return warDoc(dateId).collection('meta').doc('leaderboard');
  }

  static DocumentReference<Map<String, dynamic>> curriculumStateDoc() {
    return FirebaseFirestore.instance
        .collection(stateCollection)
        .doc(curriculumDocId);
  }

  static DocumentReference<Map<String, dynamic>> profileDoc(String uid) {
    return FirebaseFirestore.instance.collection(profilesCollection).doc(uid);
  }
}
