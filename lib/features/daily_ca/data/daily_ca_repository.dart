import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/database/question_bank_upsert.dart';
import '../../../core/database/user_db.dart';
import 'daily_ca_firestore.dart';

class DailyCaDayDocument {
  const DailyCaDayDocument({
    required this.date,
    required this.firestorePath,
    required this.questionCount,
    required this.questions,
  });

  final String date;
  final String firestorePath;
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

  /// Loads one day's MCQs from Firestore at `daily_mcqs/{year}/{month}/{day}`.
  Future<DailyCaDayDocument?> fetchDay(String isoDate) async {
    final path = DailyCaFirestore.pathForDate(isoDate);
    try {
      final snap = await DailyCaFirestore.dayDoc(isoDate).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;

      final rawQuestions = data['questions'];
      if (rawQuestions is! List || rawQuestions.isEmpty) return null;

      final questions = rawQuestions
          .whereType<Map>()
          .map((e) => _normalizeQuestionMap(Map<String, dynamic>.from(e)))
          .toList();

      if (questions.isEmpty) return null;

      final meta = data['metadata'];
      final countFromMeta = meta is Map ? meta['question_count'] : null;
      final count = countFromMeta is int ? countFromMeta : questions.length;

      return DailyCaDayDocument(
        date: isoDate,
        firestorePath: path,
        questionCount: count,
        questions: questions,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw DailyCaPermissionDeniedException(isoDate, firestorePath: path);
      }
      rethrow;
    }
  }

  /// Reads Firestore (`daily_mcqs/year/month/day`), upserts locally, returns UUIDs.
  Future<List<String>> ensureCachedForDate(String isoDate) async {
    final doc = await fetchDay(isoDate);
    if (doc != null) {
      return _upsert.upsertCurrentAffairsDocument(
        sourceDate: isoDate,
        questionMaps: doc.questions,
      );
    }

    // Offline fallback: previously synced local copy.
    final local = await _db.questionsDao.getCurrentAffairsByDate(isoDate);
    if (local.isNotEmpty) {
      return local.map((q) => q.uuid).toList();
    }

    throw DailyCaNotAvailableException(
      isoDate,
      firestorePath: DailyCaFirestore.pathForDate(isoDate),
    );
  }

  /// Canonical `{ uuid, meta, shared, en, hi }` or legacy `{ shared, en, hi }`.
  static Map<String, dynamic> _normalizeQuestionMap(Map<String, dynamic> q) {
    if (q.containsKey('meta') && q['meta'] is Map) {
      return q;
    }

    final shared = q['shared'] is Map
        ? Map<String, dynamic>.from(q['shared'] as Map)
        : <String, dynamic>{};

    return {
      if (q['uuid'] != null) 'uuid': q['uuid'],
      'meta': {
        'gs_subject': shared['subject'] ?? shared['gs_subject'] ?? '',
        'topic': shared['topic'] ?? '',
        'sub_topic': shared['subtopic'] ?? shared['sub_topic'] ?? 'Current Affairs',
        'pool_order': shared['pool_order'],
      },
      'shared': {
        'question_type': shared['question_type'],
        'trap_type': shared['trap_type'],
        'concept_anchor': shared['concept_anchor'],
        'has_table': shared['has_table'] ?? false,
        'correct_option': shared['correct_option'],
      },
      'en': q['en'] is Map ? Map<String, dynamic>.from(q['en'] as Map) : <String, dynamic>{},
      'hi': q['hi'] is Map ? Map<String, dynamic>.from(q['hi'] as Map) : <String, dynamic>{},
    };
  }
}

class DailyCaNotAvailableException implements Exception {
  DailyCaNotAvailableException(this.date, {this.firestorePath});

  final String date;
  final String? firestorePath;

  @override
  String toString() {
    final path = firestorePath;
    if (path != null) {
      return 'Daily CA not available for $date (Firestore: $path)';
    }
    return 'Daily CA not available for $date';
  }
}

class DailyCaPermissionDeniedException implements Exception {
  DailyCaPermissionDeniedException(this.date, {this.firestorePath});

  final String date;
  final String? firestorePath;

  @override
  String toString() =>
      'Firestore permission denied for daily_mcqs ($date). '
      'Deploy firestore.rules: firebase deploy --only firestore:rules';
}
