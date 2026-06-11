import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore paths for question corrections (read-only on clients).
abstract final class QuestionCorrectionsFirestore {
  QuestionCorrectionsFirestore._();

  static const collectionName = 'question_corrections';
  static const activeDocId = 'active';

  static DocumentReference<Map<String, dynamic>> activeDoc([
    FirebaseFirestore? firestore,
  ]) {
    final db = firestore ?? FirebaseFirestore.instance;
    return db.collection(collectionName).doc(activeDocId);
  }
}
