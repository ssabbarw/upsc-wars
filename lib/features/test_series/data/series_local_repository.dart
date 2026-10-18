import 'package:drift/drift.dart';

import '../../../core/constants/question_source_constants.dart';
import '../../../core/database/user_db.dart';
import '../domain/series_stats.dart';

/// Reads the user's Test Series history from the local database.
///
/// Only **scored** attempts count: sessions created with a `series_id` and the
/// `test_series` analytics key. Unscored practice re-attempts carry no
/// `series_id`, so they never touch series stats.
class SeriesLocalRepository {
  SeriesLocalRepository(this._db);

  final UserDatabase _db;

  static const _scoredKey = QuestionSourceConstants.analyticsTestSeries;

  /// Completed scored attempts of [seriesId], earliest first.
  Future<List<SeriesTestAttempt>> completedAttempts(String seriesId) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT s.id AS sid, s.series_test_id AS tid, s.completed_at AS completed_at,
             s.question_count AS qc,
             SUM(CASE WHEN a.status = 'correct' THEN 1 ELSE 0 END) AS correct,
             SUM(CASE WHEN a.status = 'wrong' THEN 1 ELSE 0 END) AS wrong
      FROM sessions s
      LEFT JOIN attempts a ON a.session_id = s.id
      WHERE s.series_id = ? AND s.status = 'completed'
        AND s.analytics_feature_key = ? AND s.series_test_id IS NOT NULL
      GROUP BY s.id
      ORDER BY s.completed_at ASC
      ''',
          variables: [
            Variable.withString(seriesId),
            Variable.withString(_scoredKey),
          ],
          readsFrom: {_db.sessions, _db.sessionQuestions},
        )
        .get();
    return [
      for (final r in rows)
        SeriesTestAttempt(
          testId: r.read<String>('tid'),
          sessionId: r.read<String>('sid'),
          completedAt: r.read<DateTime?>('completed_at'),
          correct: r.read<int?>('correct') ?? 0,
          wrong: r.read<int?>('wrong') ?? 0,
          questionCount: r.read<int?>('qc') ?? 0,
        ),
    ];
  }

  /// Answers of completed scored attempts grouped by
  /// test/subject/topic/confidence.
  Future<List<SeriesAnswerRow>> answerRows(String seriesId) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT s.series_test_id AS tid, q.gs_subject AS gs, q.topic AS topic,
             q.source_kind AS kind, a.status AS status,
             a.confidence AS conf, COUNT(*) AS n
      FROM attempts a
      JOIN sessions s ON s.id = a.session_id
      JOIN questions q ON q.uuid = a.question_uuid
      WHERE s.series_id = ? AND s.status = 'completed'
        AND s.analytics_feature_key = ? AND s.series_test_id IS NOT NULL
        AND a.status IN ('correct', 'wrong')
      GROUP BY s.series_test_id, q.gs_subject, q.topic, q.source_kind,
               a.status, a.confidence
      ''',
          variables: [
            Variable.withString(seriesId),
            Variable.withString(_scoredKey),
          ],
          readsFrom: {_db.sessions, _db.sessionQuestions, _db.questions},
        )
        .get();
    return [
      for (final r in rows)
        SeriesAnswerRow(
          testId: r.read<String>('tid'),
          gsSubject: r.read<String?>('gs') ?? '',
          topic: r.read<String?>('topic') ?? '',
          sourceKind:
              r.read<String?>('kind') ?? QuestionSourceConstants.kindStatic,
          isCorrect: r.read<String>('status') == 'correct',
          confidence: r.read<String?>('conf'),
          count: r.read<int?>('n') ?? 0,
        ),
    ];
  }

  /// Every question the user met in completed scored attempts of [testIds],
  /// one row per attempted question, for topic revision.
  Future<List<SeriesQuestionAnswer>> questionAnswers(
    String seriesId,
    Set<String> testIds,
  ) async {
    if (testIds.isEmpty) return const [];
    final placeholders = List.filled(testIds.length, '?').join(',');
    final rows = await _db
        .customSelect(
          '''
      SELECT a.question_uuid AS uuid, q.gs_subject AS gs, q.topic AS topic,
             q.source_kind AS kind, a.status AS status, a.confidence AS conf
      FROM attempts a
      JOIN sessions s ON s.id = a.session_id
      JOIN questions q ON q.uuid = a.question_uuid
      WHERE s.series_id = ? AND s.status = 'completed'
        AND s.analytics_feature_key = ?
        AND s.series_test_id IN ($placeholders)
      ''',
          variables: [
            Variable.withString(seriesId),
            Variable.withString(_scoredKey),
            ...testIds.map(Variable.withString),
          ],
          readsFrom: {_db.sessions, _db.sessionQuestions, _db.questions},
        )
        .get();
    return [
      for (final r in rows)
        SeriesQuestionAnswer(
          uuid: r.read<String>('uuid'),
          gsSubject: r.read<String?>('gs') ?? '',
          topic: r.read<String?>('topic') ?? '',
          sourceKind:
              r.read<String?>('kind') ?? QuestionSourceConstants.kindStatic,
          status: r.read<String?>('status') ?? '',
          confidence: r.read<String?>('conf'),
        ),
    ];
  }

  /// `testId -> sessionId` for scored attempts that were started but not
  /// finished (so the user can resume).
  Future<Map<String, String>> inProgressSessions(String seriesId) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT id, series_test_id FROM sessions
      WHERE series_id = ? AND status = 'in_progress'
        AND analytics_feature_key = ? AND series_test_id IS NOT NULL
      ORDER BY created_at DESC
      ''',
          variables: [
            Variable.withString(seriesId),
            Variable.withString(_scoredKey),
          ],
          readsFrom: {_db.sessions},
        )
        .get();
    final out = <String, String>{};
    for (final r in rows) {
      out.putIfAbsent(
        r.read<String>('series_test_id'),
        () => r.read<String>('id'),
      );
    }
    return out;
  }

  /// Series ids the user has at least started (owned or not), newest first.
  Future<List<String>> seriesIdsWithSessions() async {
    final rows = await _db
        .customSelect(
          '''
      SELECT series_id, MAX(created_at) AS latest FROM sessions
      WHERE series_id IS NOT NULL AND analytics_feature_key = ?
      GROUP BY series_id ORDER BY latest DESC
      ''',
          variables: [Variable.withString(_scoredKey)],
          readsFrom: {_db.sessions},
        )
        .get();
    return [for (final r in rows) r.read<String>('series_id')];
  }

  /// Which of [uuids] already exist in the local question bank.
  Future<Set<String>> existingQuestionUuids(List<String> uuids) async {
    if (uuids.isEmpty) return {};
    final found = <String>{};
    const chunk = 400;
    for (var i = 0; i < uuids.length; i += chunk) {
      final part = uuids.sublist(
        i,
        i + chunk > uuids.length ? uuids.length : i + chunk,
      );
      final placeholders = List.filled(part.length, '?').join(',');
      final rows = await _db
          .customSelect(
            'SELECT uuid FROM questions WHERE uuid IN ($placeholders)',
            variables: part.map(Variable.withString).toList(),
            readsFrom: {_db.questions},
          )
          .get();
      for (final r in rows) {
        found.add(r.read<String>('uuid'));
      }
    }
    return found;
  }
}
