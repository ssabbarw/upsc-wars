import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/domain/repositories/create_session_repository.dart';

class CreateSessionRepositoryImpl implements CreateSessionRepository {
  CreateSessionRepositoryImpl({required UserDatabase userDatabase})
    : _userDatabase = userDatabase;

  final UserDatabase _userDatabase;

  static const _uuid = Uuid();

  @override
  Future<String> createSession(SessionConfig config) async {
    final attempted = await _userDatabase.sessionQuestionsDao
        .getAllAttemptedQuestionUuids();
    final want = config.questionCount;
    if (want <= 0) {
      throw StateError('Invalid question count');
    }

    final List<Question> picked;
    final topic = config.topic;
    if (config.specificQuestionUuids != null) {
      final uuids = config.specificQuestionUuids!;
      picked = await _userDatabase.questionsDao.getByUuidsInOrder(uuids);
      if (config.requireAllSpecificUuids && picked.length != uuids.length) {
        throw MissingQuestionsException(
          wanted: uuids.length,
          found: picked.length,
        );
      }
    } else if (config.subject == 'revision') {
      final active = await _userDatabase.revisionQueueDao.fetchActiveQueue();
      final uuids = active
          .take(config.questionCount)
          .map((e) => e.questionUuid)
          .toList();
      picked = await _userDatabase.questionsDao.getByUuidsInOrder(uuids);
    } else if (config.subject == 'revision_quick') {
      final uuids = await _userDatabase.revisionQueueDao
          .fetchActiveQueueRandomized(config.questionCount);
      picked = await _userDatabase.questionsDao.getByUuidsInOrder(uuids);
    } else if (config.subject == 'bookmarks') {
      final uuids = await _userDatabase.bookmarksDao.getRandomBookmarkUuids(
        config.questionCount,
      );
      picked = await _userDatabase.questionsDao.getByUuidsInOrder(uuids);
    } else if (config.subject == 'misc') {
      picked = await _userDatabase.questionsDao.getUnseenFirstRandomMixed(
        limit: want,
        attemptedQuestionUuids: attempted,
      );
    } else if (topic != null) {
      final sub = config.subTopic?.trim();
      if (sub != null && sub.isNotEmpty) {
        var subPicked = await _userDatabase.questionsDao
            .getUnseenFirstByTopicSubTopic(
              subject: config.subject,
              topic: topic,
              subTopic: sub,
              limit: want,
              attemptedQuestionUuids: attempted,
            );
        if (subPicked.isEmpty) {
          subPicked = await _userDatabase.questionsDao.getUnseenFirstByTopic(
            subject: config.subject,
            topic: topic,
            limit: want,
            attemptedQuestionUuids: attempted,
          );
        }
        picked = subPicked;
      } else {
        picked = await _userDatabase.questionsDao.getUnseenFirstByTopic(
          subject: config.subject,
          topic: topic,
          limit: want,
          attemptedQuestionUuids: attempted,
        );
      }
    } else {
      picked = await _userDatabase.questionsDao.getUnseenFirstBySubject(
        subject: config.subject,
        limit: want,
        attemptedQuestionUuids: attempted,
      );
    }

    final n = picked.length;
    if (n == 0) {
      throw StateError('No questions available');
    }

    final sessionId = _uuid.v4();

    await _userDatabase.transaction(() async {
      await _userDatabase.sessionsDao.insertSession(
        SessionsCompanion.insert(
          id: sessionId,
          createdAt: DateTime.now(),
          subject: config.subject,
          topic: Value(config.topic),
          subTopic: Value(config.subTopic),
          mode: config.mode,
          status: 'in_progress',
          questionCount: n,
          isTimed: config.isTimed,
          timeLimitSecs: Value(config.timeLimitSecs),
          examRemainingSecs:
              (config.mode == 'exam' &&
                  config.isTimed &&
                  config.timeLimitSecs != null)
              ? Value(config.timeLimitSecs)
              : const Value.absent(),
          language: Value(config.language),
          analyticsFeatureKey: Value(config.analyticsFeatureKey),
          seriesId: Value(config.seriesId),
          seriesTestId: Value(config.seriesTestId),
          practiceTestId: Value(config.practiceTestId),
        ),
      );
      for (var i = 0; i < n; i++) {
        await _userDatabase.sessionQuestionsDao.insertSessionQuestion(
          SessionQuestionsCompanion.insert(
            id: _uuid.v4(),
            sessionId: sessionId,
            questionUuid: picked[i].uuid,
            position: i + 1,
          ),
        );
      }
    });

    final historyConf = config.dangerReviseHistoryConfidence;
    if (historyConf != null &&
        config.specificQuestionUuids != null &&
        config.specificQuestionUuids!.isNotEmpty) {
      await _hydrateDangerReviseFromHistory(
        _userDatabase,
        sessionId: sessionId,
        confidence: historyConf,
        questionUuids: picked.map((q) => q.uuid).toList(),
      );
    }

    return sessionId;
  }

  @override
  Future<void> importSessionWithFixedId({
    required String sessionId,
    required SessionConfig config,
  }) async {
    final existing = await _userDatabase.sessionsDao.getSessionById(sessionId);
    if (existing != null) return;

    final uuids = config.specificQuestionUuids;
    if (uuids == null || uuids.isEmpty) {
      throw StateError(
        'importSessionWithFixedId requires specificQuestionUuids',
      );
    }

    final picked = await _userDatabase.questionsDao.getByUuidsInOrder(uuids);
    if (picked.length != uuids.length) {
      throw StateError('Some question UUIDs are missing from the local DB');
    }

    final n = picked.length;
    if (n == 0) throw StateError('No questions available');

    await _userDatabase.transaction(() async {
      await _userDatabase.sessionsDao.insertSession(
        SessionsCompanion.insert(
          id: sessionId,
          createdAt: DateTime.now(),
          subject: config.subject,
          topic: Value(config.topic),
          subTopic: Value(config.subTopic),
          mode: config.mode,
          status: 'in_progress',
          questionCount: n,
          isTimed: config.isTimed,
          timeLimitSecs: Value(config.timeLimitSecs),
          examRemainingSecs:
              (config.mode == 'exam' &&
                  config.isTimed &&
                  config.timeLimitSecs != null)
              ? Value(config.timeLimitSecs)
              : const Value.absent(),
          language: Value(config.language),
          analyticsFeatureKey: Value(config.analyticsFeatureKey),
          seriesId: Value(config.seriesId),
          seriesTestId: Value(config.seriesTestId),
          practiceTestId: Value(config.practiceTestId),
        ),
      );
      for (var i = 0; i < n; i++) {
        await _userDatabase.sessionQuestionsDao.insertSessionQuestion(
          SessionQuestionsCompanion.insert(
            id: _uuid.v4(),
            sessionId: sessionId,
            questionUuid: picked[i].uuid,
            position: i + 1,
          ),
        );
      }
    });
  }
}

const _hydrateInChunk = 350;

Future<Map<String, String>> _fetchLastWrongSelectionsByQuestion(
  UserDatabase db, {
  required String confidence,
  required List<String> questionUuids,
}) async {
  if (questionUuids.isEmpty) return {};
  final out = <String, String>{};
  for (var i = 0; i < questionUuids.length; i += _hydrateInChunk) {
    final end = i + _hydrateInChunk > questionUuids.length
        ? questionUuids.length
        : i + _hydrateInChunk;
    final part = questionUuids.sublist(i, end);
    final placeholders = List.filled(part.length, '?').join(',');
    final rows = await db
        .customSelect(
          '''
      SELECT q1.question_uuid AS quid, q1.selected_option AS sel
      FROM attempts q1
      INNER JOIN (
        SELECT question_uuid, MAX(attempted_at) AS mx
        FROM attempts
        WHERE question_uuid IN ($placeholders)
          AND confidence = ?
          AND attempted_at IS NOT NULL
          AND status = 'wrong'
          AND IFNULL(is_correct, 0) = 0
        GROUP BY question_uuid
      ) t ON t.question_uuid = q1.question_uuid
        AND q1.attempted_at = t.mx
        AND q1.confidence = ?
      ''',
          variables: [
            ...part.map(Variable.withString),
            Variable.withString(confidence),
            Variable.withString(confidence),
          ],
          readsFrom: {db.sessionQuestions},
        )
        .get();
    for (final r in rows) {
      final quid = r.read<String>('quid');
      final sel = r.read<String?>('sel');
      if (sel != null && sel.trim().isNotEmpty) {
        out[quid] = sel;
      }
    }
  }
  return out;
}

Future<void> _hydrateDangerReviseFromHistory(
  UserDatabase db, {
  required String sessionId,
  required String confidence,
  required List<String> questionUuids,
}) async {
  final prior = await _fetchLastWrongSelectionsByQuestion(
    db,
    confidence: confidence,
    questionUuids: questionUuids,
  );
  if (prior.isEmpty) return;

  final rows = await db.sessionQuestionsDao.getSessionQuestionsOrdered(
    sessionId,
  );
  final now = DateTime.now();
  const valid = {'a', 'b', 'c', 'd'};

  for (final sq in rows) {
    final raw = prior[sq.questionUuid];
    if (raw == null) continue;
    final opt = raw.trim().toLowerCase();
    if (!valid.contains(opt)) continue;

    await db.sessionQuestionsDao.updateSessionQuestionFields(
      sq.id,
      selectedOption: Value(opt),
      isCorrect: Value(false),
      status: Value('wrong'),
      attemptedAt: Value(now),
      confidence: Value(confidence),
    );
  }
}
