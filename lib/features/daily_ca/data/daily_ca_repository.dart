import '../../../core/database/question_bank_upsert.dart';
import '../../../core/database/user_db.dart';
import 'daily_ca_firestore.dart';

class DailyCaDayDocument {
  const DailyCaDayDocument({
    required this.date,
    required this.questionCount,
    required this.questions,
  });

  final String date;
  final int questionCount;
  final List<Map<String, dynamic>> questions;
}

class DailyCaRepository {
  DailyCaRepository({
    required UserDatabase db,
  }) : _db = db,
       _upsert = QuestionBankUpsert(db);

  final UserDatabase _db;
  final QuestionBankUpsert _upsert;

  Future<DailyCaDayDocument?> fetchDay(String isoDate) async {
    final snap = await DailyCaFirestore.dayDoc(isoDate).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;

    final rawQuestions = data['questions'];
    if (rawQuestions is! List || rawQuestions.isEmpty) return null;

    final questions = rawQuestions
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final meta = data['metadata'];
    final countFromMeta = meta is Map ? meta['question_count'] : null;
    final count = countFromMeta is int ? countFromMeta : questions.length;

    return DailyCaDayDocument(
      date: isoDate,
      questionCount: count,
      questions: questions,
    );
  }

  /// Fetches from Firestore when needed, upserts locally, returns ordered UUIDs.
  Future<List<String>> ensureCachedForDate(String isoDate) async {
    final local = await _db.questionsDao.getCurrentAffairsByDate(isoDate);
    if (local.isNotEmpty) {
      return local.map((q) => q.uuid).toList();
    }

    final doc = await fetchDay(isoDate);
    if (doc == null) {
      throw DailyCaNotAvailableException(isoDate);
    }

    return _upsert.upsertCurrentAffairsDocument(
      sourceDate: isoDate,
      questionMaps: doc.questions,
    );
  }
}

class DailyCaNotAvailableException implements Exception {
  DailyCaNotAvailableException(this.date);

  final String date;

  @override
  String toString() => 'Daily CA not available for $date';
}
